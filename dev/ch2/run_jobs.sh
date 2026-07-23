#!/usr/bin/env bash
# =====================================================================
# run_jobs.sh -- a reusable concurrent job runner for the Chapter 2/3 work.
#
# You describe the work in a plain-text manifest (one job per line); this script
# runs as many as the core budget allows at once, queues the rest, writes one
# log per job, and prints a combined summary at the end. It is the single
# launcher to reuse for every future batch -- recovery runs, Shigella fits,
# Chapter 3 -- instead of writing a new bespoke script each time.
#
# ---------------------------------------------------------------------
# MANIFEST FORMAT  (default file: jobs.tsv, override with JOBS=...)
# ---------------------------------------------------------------------
# Tab- or whitespace-separated. Blank lines and lines starting with # ignored.
#
#   <job_name>  <script>  KEY=VAL KEY=VAL ...
#
# Every KEY=VAL is exported into that job's environment only. The runner adds
# nothing implicitly, so a job is fully described by its line. Example:
#
#   rerun_n150_s3   ch2_run_one.R   N_SUBJ=150 SEED=3 ADAPT_DELTA=0.999 WARMUP=9000 SAMP=4000 NCHAIN=8 TAG=rerun_n150_s3
#   shig_fit_igg    fit_shigella.R  ANTIGEN=IgG NCHAIN=8 TAG=shig_igg
#
# ---------------------------------------------------------------------
# CORE BUDGET
# ---------------------------------------------------------------------
# Set CORES_PER_JOB to the NCHAIN each job uses (they run chains in parallel).
# The runner keeps at most floor(MAX_CORES / CORES_PER_JOB) jobs alive at once
# and starts the next queued job as soon as a slot frees. MAX_CORES defaults to
# nproc; leave a couple free with e.g. MAX_CORES=$(( $(nproc) - 2 )).
#
# ---------------------------------------------------------------------
# USAGE
# ---------------------------------------------------------------------
#   chmod +x run_jobs.sh
#   JOBS=jobs_rerun.tsv CORES_PER_JOB=8 nohup ./run_jobs.sh > jobs.out 2>&1 &
#   tail -f jobs.out
#
#   # watch just the queue state:
#   grep -E "START|DONE|QUEUE" jobs.out
# =====================================================================
set -uo pipefail
cd "$(dirname "$0")" || exit 1

JOBS="${JOBS:-jobs.tsv}"
MAX_CORES="${MAX_CORES:-$(nproc)}"
CORES_PER_JOB="${CORES_PER_JOB:-8}"
SLOTS=$(( MAX_CORES / CORES_PER_JOB )); [ "$SLOTS" -lt 1 ] && SLOTS=1
STAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="jobs_${STAMP}"
mkdir -p "$LOGDIR"
ts() { date '+%Y-%m-%d %H:%M:%S'; }

[ -f "$JOBS" ] || { echo "[$(ts)] manifest not found: $JOBS"; exit 1; }

echo "[$(ts)] ###### run_jobs: $JOBS ######"
echo "[$(ts)] MAX_CORES=$MAX_CORES  CORES_PER_JOB=$CORES_PER_JOB  concurrent slots=$SLOTS"
echo "[$(ts)] logs -> $LOGDIR/"

# ---- parse manifest into arrays -------------------------------------
names=(); scripts=(); envs=()
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"
  [ -z "${line// }" ] && continue
  read -r nm sc rest <<< "$line"
  names+=("$nm"); scripts+=("$sc"); envs+=("$rest")
done < "$JOBS"
N=${#names[@]}
echo "[$(ts)] $N job(s) queued"

# ---- global settings passed to EVERY job (manifest KEY=VALs override) ----
# PKG_DIR is required by the R workers (devtools::load_all). Without it they die
# immediately with an empty-path error, so it is exported here for all jobs.
export PKG_DIR="${PKG_DIR:-$HOME/chapter 2 work/serodynamics}"
export MODEL_STAN="${MODEL_STAN:-model_ch2.stan}"
echo "[$(ts)] PKG_DIR=$PKG_DIR"
if [ ! -f "$PKG_DIR/DESCRIPTION" ]; then
  echo "[$(ts)] ABORT: no DESCRIPTION at PKG_DIR ($PKG_DIR)."
  echo "[$(ts)]   set PKG_DIR=... on the command line to your package root."
  exit 1
fi

# ---- lightweight preflight: every distinct script must exist --------
miss=0
for sc in $(printf '%s\n' "${scripts[@]}" | sort -u); do
  [ -f "$sc" ] || { echo "[$(ts)] MISSING script: $sc"; miss=1; }
done
[ "$miss" -ne 0 ] && { echo "[$(ts)] aborting -- fix missing scripts."; exit 1; }

# ---- dispatch loop with a bounded number of live jobs ---------------
declare -A PID2NAME
running=0; idx=0; rc=0
reap() {   # block until at least one job exits, then harvest all finished
  wait -n 2>/dev/null || true
  for p in "${!PID2NAME[@]}"; do
    if ! kill -0 "$p" 2>/dev/null; then
      wait "$p"; code=$?
      echo "[$(ts)] DONE  ${PID2NAME[$p]} (exit $code)"
      [ "$code" -ne 0 ] && rc=1
      unset 'PID2NAME[$p]'; running=$((running-1))
    fi
  done
}

while [ "$idx" -lt "$N" ] || [ "$running" -gt 0 ]; do
  while [ "$running" -lt "$SLOTS" ] && [ "$idx" -lt "$N" ]; do
    nm="${names[$idx]}"; sc="${scripts[$idx]}"; ev="${envs[$idx]}"
    log="$LOGDIR/${nm}.out"
    echo "[$(ts)] START ${nm}  ($sc)  [$ev]"
    ( export CORES_PER_JOB PKG_DIR MODEL_STAN; eval "export $ev" 2>/dev/null; \
      NCHAIN="${NCHAIN:-$CORES_PER_JOB}" Rscript "$sc" ) > "$log" 2>&1 &
    PID2NAME[$!]="$nm"; running=$((running+1)); idx=$((idx+1))
    echo "[$(ts)] QUEUE running=$running queued=$((N-idx))"
    sleep 3
  done
  [ "$running" -ge "$SLOTS" ] || [ "$idx" -ge "$N" ] && reap
done

echo "[$(ts)] all jobs finished (rc=$rc)"

# ---- combined summary from any res_*.rds the jobs wrote -------------
echo
echo "===================== JOBS SUMMARY ====================="
Rscript -e '
f <- Sys.glob("res_*.rds")
if (!length(f)) { cat("no res_*.rds found\n"); quit(status = 0) }
rows <- lapply(f, function(p) {
  r <- try(readRDS(p), silent = TRUE); if (inherits(r, "try-error")) return(NULL)
  sm <- r$summary; ds <- r$diagnostics
  tot <- tryCatch(r$settings$nchain * r$settings$samp, error = function(e) NA)
  data.frame(
    tag = if (!is.null(r$tag)) r$tag else sub("^res_|\\.rds$", "", basename(p)),
    n = tryCatch(r$settings$n, error = function(e) NA),
    min = tryCatch(round(r$minutes, 1), error = function(e) NA),
    rhat = if (is.null(sm)) NA else round(max(sm$rhat, na.rm = TRUE), 3),
    ess  = if (is.null(sm)) NA else round(min(sm$ess_bulk, na.rm = TRUE)),
    div  = if (is.null(ds)) NA else sum(ds$num_divergent),
    td_pct = if (is.null(ds) || is.na(tot)) NA else round(100 * sum(ds$num_max_treedepth) / tot, 1),
    keep = if (is.null(sm)) NA else (max(sm$rhat, na.rm = TRUE) < 1.1),
    stringsAsFactors = FALSE)
})
o <- do.call(rbind, rows); o <- o[order(o$tag), ]
print(o, row.names = FALSE)
cat("\npassing R-hat < 1.1:", sum(o$keep, na.rm = TRUE), "/", nrow(o), "\n")
' 2>&1
echo "======================================================="
echo "[$(ts)] DONE. per-job logs in $LOGDIR/, results in res_*.rds"
