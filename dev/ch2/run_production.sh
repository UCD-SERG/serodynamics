#!/usr/bin/env bash
# =====================================================================
# run_production.sh -- PHASE 2 (launch before bed, ~7 h)
#
# Delivers Ezra's four metrics -- bias, MSE, posterior variance, coverage --
# across seeds, at TWO sample sizes in one window:
#
#   *"First, you do large sample, then you do realistic sizes."*
#   *"rather than prediction error should be focused on bias and mean square
#     error for the model parameters"*
#   *"I would focus on the variance of the posterior distributions"*
#   *"and coverage, just like you did in chapter one"*
#
#   LARGE arm      N_LARGE (default 150)  -- see the note on n below
#   REALISTIC arm  N_REAL  (default 129)  -- matches nepal_sees exactly
#
# WHY ONLY n=150 AND NOT n=250/500.  The probe (2026-07-21) showed the latent
# dimension, not treedepth, is the binding constraint: `par` is nsubj x 10, so
# the posterior grows linearly in n.  At n=150/td=12 the geometry is clean
# (0% treedepth saturation, 0 divergences, ebfmi 0.70) and 27 of 32 structural
# parameters already had R-hat < 1.1 on only 600 warmup iterations.  At n=250 the
# sampler saturates treedepth 100% even at td=12 and R-hat degrades.  Raising
# td to 13 doubles cost and does not fit the window.
#
# WHY warmup 6000.  The probe used 600 and still reached R-hat < 1.1 on 27/32
# parameters.  The nepal_sees production fit used warmup 6000 (Ch2) / 8000 (Ch1)
# and reached R-hat 1.040.  Warmup, not treedepth, is the lever here.
#
# KNOWN HARD PARAMETERS.  cross_corr[1] (baseline) and cross_corr[5]
# (decay-shape) are the last to converge, in the probe AND in the real nepal fit
# (where cross_corr[1] had ESS-tail 124 of 16,032 draws).  This is a property of
# the estimand, not of the simulation, and should be reported as such.
#
# 8 seeds per arm, not 6: the earlier s2 study lost seed 3 to R-hat 1.28, and a
# failed seed cannot be re-run in a 3-hour morning window. 8 leaves margin to
# drop 2 and still report 6.
#
# Cores: 2 arms x 8 seeds x NCHAIN(6) = 96, matching the nepal production run.
# Wall time = the slower arm, since everything runs concurrently.
#
# Worst-case (full treedepth saturation; faster if the probe cleared it):
#   LARGE n=150 td=12 9000 iter  ~4.1 h   <- pacing arm
#   REAL  n=129 td=12 9000 iter  ~3.6 h
# (calibrated on the measured probe rate: 27.6 min / 1000 iter at n=150, td=12)
#
# SET N_LARGE AND MAX_TD FROM THE PHASE-1 PROBE TABLE before launching.
#
# USAGE:
#   chmod +x run_production.sh
#   nohup ./run_production.sh > production.out 2>&1 &
#
# Null arm (nesting check -- does the model return rho = 0 when the truth is 0?):
#   RHO_SCALE=0 SIZES=129 nohup ./run_production.sh > null.out 2>&1 &
#   tail -f production.out
#

# =====================================================================
set -uo pipefail
cd "$(dirname "$0")" || exit 1

export PKG_DIR="${PKG_DIR:-$HOME/chapter 2 work/serodynamics}"
export ARM=noise
export MAX_N_OBS="${MAX_N_OBS:-20}"
export NCHAIN="${NCHAIN:-6}"
export WARMUP="${WARMUP:-6000}"
export SAMP="${SAMP:-3000}"
export ADAPT_DELTA="${ADAPT_DELTA:-0.9}"
export MAX_TD="${MAX_TD:-12}"
export CH2_DIR="${CH2_DIR:-.}"

N_LARGE="${N_LARGE:-150}"
N_REAL="${N_REAL:-129}"
SEEDS="${SEEDS:-1 2 3 4 5 6 7 8}"
SIZES="${SIZES:-$N_LARGE $N_REAL}"
export RHO_SCALE="${RHO_SCALE:-1}"

STAMP=$(date +%Y%m%d_%H%M%S); ts() { date '+%Y-%m-%d %H:%M:%S'; }
NSEED=$(echo $SEEDS | wc -w); NSIZE=$(echo $SIZES | wc -w)
CORES=$(( NSEED * NSIZE * NCHAIN ))

echo "[$(ts)] ###### PHASE 2: production recovery run ######"
echo "[$(ts)] sizes=$SIZES | seeds=$SEEDS | chains=$NCHAIN | max_td=$MAX_TD | rho_scale=$RHO_SCALE"
echo "[$(ts)] iterations=$WARMUP warmup + $SAMP samp | total processes=$(( NSEED*NSIZE )) | cores=$CORES"

fail=0
for f in ch2_run_one.R DESCRIPTION R/stan_ch2_functions.R \
         R/ch2_sim_functions.R inst/extdata/model_ch2.stan; do
  [ -f "$f" ] || { echo "[$(ts)] MISSING: $f"; fail=1; }
done
[ -d "$PKG_DIR" ] || { echo "[$(ts)] MISSING: $PKG_DIR"; fail=1; }

AVAILCPU=$(nproc); AVAILMEM=$(free -g | awk '/^Mem:/{print $7}')
echo "[$(ts)] host: $AVAILCPU cores, ${AVAILMEM} GB available"
[ "$CORES" -gt "$AVAILCPU" ] && { echo "[$(ts)] REFUSING: need $CORES cores, host has $AVAILCPU."; echo "[$(ts)]   reduce SEEDS or NCHAIN."; fail=1; }
# each process caches draws for log_lik + par + z; roughly 1 GB at n=250 x 9000 draws
NEEDMEM=$(( NSEED * NSIZE ))
[ "$AVAILMEM" -lt "$NEEDMEM" ] && echo "[$(ts)] WARNING: ~${NEEDMEM} GB may be needed, ${AVAILMEM} GB free. Consider fewer seeds."

[ "$fail" -ne 0 ] && { echo "[$(ts)] PREFLIGHT FAILED -- nothing launched."; exit 1; }
echo "[$(ts)] preflight passed. launching $(( NSEED*NSIZE )) processes..."

pids=""
for n in $SIZES; do
  for s in $SEEDS; do
    if [ "$RHO_SCALE" = "1" ]; then tag="prod_n${n}_td${MAX_TD}_s${s}"
    else tag="null_n${n}_td${MAX_TD}_s${s}"; fi
    TAG="$tag" N_SUBJ="$n" SEED="$s" nohup Rscript ch2_run_one.R > "${tag}_${STAMP}.out" 2>&1 &
    pids="$pids $!"
    sleep 3
  done
  echo "[$(ts)] launched all seeds for n=$n"
done
echo "[$(ts)] pids:$pids"
echo "[$(ts)] waiting... (each cell saves res_prod_*.rds independently -- a crash in one does not affect the others)"
for p in $pids; do wait "$p" || true; done
echo "[$(ts)] all cells finished"

echo; echo "================== PRODUCTION: CONVERGENCE ROLL-CALL =================="
Rscript -e '
f <- c(Sys.glob("res_prod_*.rds"), Sys.glob("res_null_*.rds"))
if (!length(f)) { cat("no res_prod_*.rds found\n"); quit(status=0) }
rows <- lapply(f, function(p){ r <- readRDS(p); sm <- r$summary; ds <- r$diagnostics
  tot <- r$settings$nchain * r$settings$samp
  data.frame(n=r$settings$n, rho=r$rho_scale, seed=r$settings$seed, min=round(r$minutes,1),
    rhat=if(is.null(sm)) NA else round(max(sm$rhat,na.rm=TRUE),3),
    ess=if(is.null(sm)) NA else round(min(sm$ess_bulk,na.rm=TRUE)),
    div=if(is.null(ds)) NA else sum(ds$num_divergent),
    td_pct=if(is.null(ds)) NA else round(100*sum(ds$num_max_treedepth)/tot,1),
    cover=if(is.null(r$cross_corr)) NA else sum(r$cross_corr$covered),
    keep=if(is.null(sm)) FALSE else (max(sm$rhat,na.rm=TRUE) < 1.1),
    stringsAsFactors=FALSE)})
o <- do.call(rbind, rows); o <- o[order(o$rho, o$n, o$seed), ]
print(o, row.names=FALSE)
cat("\nseeds passing R-hat < 1.1:\n")
for (nn in unique(o$n)) cat("  n =", nn, ":", sum(o$n==nn & o$keep), "/", sum(o$n==nn), "\n")
cat("\nNOTE: cross_corr[1] and cross_corr[5] are the known slow parameters --\n")
cat("check whether failures are confined to those before discarding a seed.\n")
cat("\nNEXT: run ch2_recovery_metrics.R over the kept seeds for bias / MSE /\n")
cat("posterior variance / coverage. Send me this table either way.\n")
' 2>&1
echo "======================================================================="
echo "[$(ts)] DONE. res_*.rds, fit_prod_*.rds, csv_prod_*/ per cell."
