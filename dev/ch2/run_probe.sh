#!/usr/bin/env bash
# =====================================================================
# run_probe.sh -- PHASE 1 (launch now, <= 2.3 h)
#
# Answers ONE question: which (n, max_treedepth) clears the treedepth ceiling?
#
# The n=500 / td=10 run gave 0 divergences and healthy ebfmi (0.68-0.84) but
# saturated treedepth on 1000/1000 iterations of all 8 chains, with R-hat 1.6494.
# That is a tuning ceiling, not a broken posterior: at n=500 the latent dimension
# is 500 x 10 = 5,000 (plus z, ~10,000) and td=10 allows only 2^10 = 1024
# leapfrog steps per iteration.
#
# Short runs are enough here -- treedepth saturation is a property of the
# geometry, visible immediately, not something that needs 2000 iterations.
#
# Worst-case wall time (assuming FULL saturation; faster if the ceiling clears):
#   P1  n=250 td=11   1.2 h
#   P2  n=250 td=12   2.3 h   <- pacing cell
#   P3  n=150 td=12   1.4 h
# Cores: 3 x 6 = 18.
#
# USAGE:
#   chmod +x run_probe.sh
#   nohup ./run_probe.sh > probe.out 2>&1 &
#   tail -f probe.out
# =====================================================================
set -uo pipefail
cd "$(dirname "$0")" || exit 1

export PKG_DIR="${PKG_DIR:-$HOME/chapter 2 work/serodynamics}"
export ARM=noise
export MAX_N_OBS="${MAX_N_OBS:-20}"
export NCHAIN="${NCHAIN:-6}"
export WARMUP="${WARMUP:-600}"
export SAMP="${SAMP:-400}"
export ADAPT_DELTA="${ADAPT_DELTA:-0.9}"
export SEED="${SEED:-1}"
export MODEL_STAN="${MODEL_STAN:-model_ch2.stan}"

CELLS="${CELLS:-P1 P2 P3}"
P1="250:11"; P2="250:12"; P3="150:12"

STAMP=$(date +%Y%m%d_%H%M%S); ts() { date '+%Y-%m-%d %H:%M:%S'; }
echo "[$(ts)] ###### PHASE 1: tuning probe ######"
echo "[$(ts)] cells=$CELLS | chains=$NCHAIN | warmup=$WARMUP samp=$SAMP | cores=$(( $(echo $CELLS|wc -w) * NCHAIN ))"

fail=0
for f in ch2_run_one.R make_corr_curve_params.R stan_ch2_functions.R \
         ch2_sim_functions.R ch2_truth_targets.rds "$MODEL_STAN"; do
  [ -f "$f" ] && echo "[$(ts)]   ok  $f" || { echo "[$(ts)] MISSING: $f"; fail=1; }
done
[ -d "$PKG_DIR" ] || { echo "[$(ts)] MISSING: $PKG_DIR"; fail=1; }
echo "[$(ts)] memory: $(free -g | awk '/^Mem:/{print $7" GB available of "$2" GB"}')"

Rscript -e '
suppressMessages(devtools::load_all(Sys.getenv("PKG_DIR")))
source("make_corr_curve_params.R"); source("stan_ch2_functions.R"); source("ch2_sim_functions.R")
ok <- c(noise_sd = "noise_sd" %in% names(formals(sim_case_data)),
        targets  = "targets"  %in% names(formals(make_corr_curve_params)),
        truth    = file.exists("ch2_truth_targets.rds"),
        run_mod  = exists("run_mod_stan_ch2"))
print(ok); if (!all(ok)) quit(status = 1)
tg <- readRDS("ch2_truth_targets.rds"); set.seed(1)
cp <- make_corr_curve_params(200, targets = tg, rho = as.numeric(tg$cross_corr_median))
set.seed(99); s1 <- sim_case_data(20, cp, max_n_obs = 4, spacing = "log", noise_sd = c(0.2890, 0.3054))
set.seed(99); s0 <- sim_case_data(20, cp, max_n_obs = 4, spacing = "log")
stopifnot(nrow(s1) == nrow(s0), identical(s1$id, s0$id), all(s1$value > 0))
cat("dry run OK | sd(log ratio) =", sprintf("%.4f", sd(log(s1$value) - log(s0$value))), "\n")
' 2>&1 | sed "s/^/[$(ts)]   /"
[ ${PIPESTATUS[0]:-0} -eq 0 ] || fail=1
[ "$fail" -ne 0 ] && { echo "[$(ts)] PREFLIGHT FAILED -- nothing launched."; exit 1; }

pids=""
for c in $CELLS; do
  eval "spec=\$$c"; n="${spec%%:*}"; td="${spec##*:}"
  tag="probe_${c}_n${n}_td${td}"
  echo "[$(ts)] launch $c : n=$n td=$td -> ${tag}_${STAMP}.out"
  TAG="$tag" N_SUBJ="$n" MAX_TD="$td" nohup Rscript ch2_run_one.R > "${tag}_${STAMP}.out" 2>&1 &
  pids="$pids $!"; sleep 4
done
echo "[$(ts)] pids:$pids"
for p in $pids; do wait "$p" || true; done
echo "[$(ts)] probe finished"

echo; echo "===================== PROBE SUMMARY ====================="
Rscript -e '
f <- Sys.glob("res_probe_*.rds")
if (!length(f)) { cat("no res_probe_*.rds found\n"); quit(status=0) }
rows <- lapply(f, function(p){ r <- readRDS(p); sm <- r$summary; ds <- r$diagnostics
  tot <- r$settings$nchain * r$settings$samp
  data.frame(tag=r$tag, n=r$settings$n, td=r$settings$max_td, latent=r$latent_dim,
    min=round(r$minutes,1),
    prec=if(is.null(sm)) NA else paste(sprintf("%.1f",
      sm$mean[sm$variable %in% c("prec_logy[1]","prec_logy[2]")]), collapse="/"),
    rhat=if(is.null(sm)) NA else round(max(sm$rhat,na.rm=TRUE),3),
    ess=if(is.null(sm)) NA else round(min(sm$ess_bulk,na.rm=TRUE)),
    div=if(is.null(ds)) NA else sum(ds$num_divergent),
    td_pct=if(is.null(ds)) NA else round(100*sum(ds$num_max_treedepth)/tot,1),
    ebfmi=if(is.null(ds)) NA else round(min(ds$ebfmi),3),
    stringsAsFactors=FALSE)})
o <- do.call(rbind, rows); print(o[order(o$n,o$td),], row.names=FALSE)
cat("\ntruth prec_logy = 11.97 / 10.72   (n=500 td=10 gave rhat 1.649, td_pct 100)\n")
cat("DECISION RULE for tonight:\n")
cat("  td_pct < 20 and rhat < 1.2  -> use that (n, td) for PHASE 2\n")
cat("  only n=150 qualifies        -> N_LARGE=150 (still >1x the real 129 subjects)\n")
cat("  nothing qualifies           -> do NOT launch phase 2; send me this table\n")
' 2>&1
echo "========================================================="
