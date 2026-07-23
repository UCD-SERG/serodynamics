#!/usr/bin/env Rscript
# =====================================================================
# ch2_run_one.R -- ONE cell of the Chapter-2 simulation study.
#
# =====================================================================
# WHY THIS REPLACES n500_one.R
# =====================================================================
# The 2026-07-21 n=500 run completed BOTH fits (138 and 144 minutes) and then
# lost both of them: a post-processing line crashed before saveRDS(), and
# run_mod_stan_ch2() writes its CSVs to tempdir(), which R deletes on exit.
#
# Three structural fixes, in order of importance:
#
#   1. PERSIST FIRST, ANALYSE SECOND. The fit object and the raw CSVs are saved
#      immediately after sampling returns. Nothing that can throw runs before
#      that point.
#   2. EVERY post-processing block is wrapped in tryCatch. A formatting error can
#      no longer destroy hours of sampling.
#   3. The CSVs are copied out of tempdir() into ./csv_<TAG>/, so even a hard
#      kill leaves a recoverable fit (read back with
#      cmdstanr::as_cmdstan_fit(list.files("csv_<TAG>", full.names = TRUE))).
#
# Also fixed: `fit$summary(var, q5 = ~quantile(.x, .05), ...)` did not produce
# columns named q5/q95. cmdstanr's DEFAULT summary already includes q5 and q95,
# so we just call fit$summary(var) and verify the columns exist.
# =====================================================================
#
# Environment variables (all optional except PKG_DIR):
#   TAG         label for output files (default: <arm>_n<N>_td<MAX_TD>_s<SEED>)
#   ARM         "noise" (default) or "control"
#   N_SUBJ      number of simulated subjects            (default 250)
#   MAX_N_OBS   max observations per subject            (default 20)
#   NCHAIN      chains, run in parallel                 (default 8)
#   WARMUP/SAMP iterations                              (default 1000/1000)
#   ADAPT_DELTA                                         (default 0.9)
#   MAX_TD      max_treedepth                           (default 12)
#   SEED                                                (default 1)
# =====================================================================

suppressPackageStartupMessages({ library(cmdstanr) })

ARM       <- Sys.getenv("ARM", "noise"); stopifnot(ARM %in% c("noise", "control"))
PKG_DIR   <- Sys.getenv("PKG_DIR")
N_SUBJ    <- as.integer(Sys.getenv("N_SUBJ", "250"))
MAX_N_OBS <- as.integer(Sys.getenv("MAX_N_OBS", "20"))
NCHAIN    <- as.integer(Sys.getenv("NCHAIN", "8"))
WARMUP    <- as.integer(Sys.getenv("WARMUP", "1000"))
SAMP      <- as.integer(Sys.getenv("SAMP", "1000"))
ADAPT     <- as.numeric(Sys.getenv("ADAPT_DELTA", "0.9"))
MAXTD     <- as.integer(Sys.getenv("MAX_TD", "12"))
SEED      <- as.integer(Sys.getenv("SEED", "1"))
NITERCP   <- as.integer(Sys.getenv("NITER_CP", "4000"))
STAN      <- Sys.getenv("MODEL_STAN", "model_ch2.stan")
# RHO_SCALE multiplies the fitted cross-correlation vector. 1 = realistic
# scenario, 0 = null arm (nesting check: does the model return rho = 0 when the
# truth is 0?). Any value in (0, 1] is admissible -- max scale is 1.076.
RHO_SCALE <- as.numeric(Sys.getenv("RHO_SCALE", "1"))
# MIN_N_OBS controls how many visits each simulated subject gets. The log-spaced
# schedule takes the FIRST n_obs points of a fixed grid, so n_obs sets the
# observation WINDOW, not just its density: with the default uniform draw over
# 1..max_n_obs, the median subject stops at day 30 of a 400-day grid and only
# about 30% of subjects ever see the decay tail. Raising MIN_N_OBS concentrates
# the draw on the upper range so most subjects are followed to the end, which is
# the direct test of whether decay-shape is weakly identified because of the
# model or because of the design.
MIN_N_OBS <- as.integer(Sys.getenv("MIN_N_OBS", "1"))
TAG       <- Sys.getenv("TAG", sprintf("%s_n%d_td%d_s%d", ARM, N_SUBJ, MAXTD, SEED))
# SAVE_FIT=0 skips fit$save_object(). That call caches EVERY variable, including
# log_lik (one value per observation per draw), which at production settings is
# ~1.5 GB per cell in memory and again on disk. The CSVs are copied out
# regardless, so the fit stays fully recoverable without it:
#   cmdstanr::as_cmdstan_fit(list.files("csv_<TAG>", full.names = TRUE))
SAVE_FIT  <- as.integer(Sys.getenv("SAVE_FIT", "1"))

ts  <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")
say <- function(...) cat(sprintf("[%s][%s] ", ts(), TAG), ..., "\n", sep = "")
safe <- function(label, expr) tryCatch(expr, error = function(e) {
  say("!! post-processing '", label, "' failed: ", conditionMessage(e),
      "  (fit is already saved; continuing)"); invisible(NULL) })

say("start | arm=", ARM, " rho_scale=", RHO_SCALE, " n=", N_SUBJ, " mno=", MAX_N_OBS, " chains=", NCHAIN,
    " warmup=", WARMUP, " samp=", SAMP, " adapt=", ADAPT, " max_td=", MAXTD,
    " seed=", SEED)

suppressMessages(devtools::load_all(PKG_DIR))
source("make_corr_curve_params.R")
source("stan_ch2_functions.R")
source("ch2_sim_functions.R")

stopifnot(file.exists("ch2_truth_targets.rds"), file.exists(STAN))
tg  <- readRDS("ch2_truth_targets.rds")
rho <- RHO_SCALE * as.numeric(tg$cross_corr_median)

set.seed(SEED)
cp    <- make_corr_curve_params(NITERCP, targets = tg, rho = rho)
truth <- scenario_truth(curve_params = cp)
say("curve_params built | truth = ", paste(sprintf("%+.4f", truth$cross_corr), collapse = " "))

noise_sd <- if (ARM == "noise") c(0.2890, 0.3054) else 0
n_obs_grid <- seq.int(MIN_N_OBS, MAX_N_OBS)
dist_n_obs <- tibble::tibble(n_obs = n_obs_grid,
                             prob = rep(1 / length(n_obs_grid), length(n_obs_grid)))
if (MIN_N_OBS > 1L) {
  grid_days <- exp(seq(log(3), log(400), length.out = MAX_N_OBS))
  say("MIN_N_OBS = ", MIN_N_OBS, " -> every subject followed to at least day ",
      sprintf("%.0f", grid_days[MIN_N_OBS]),
      " (default MIN_N_OBS=1 leaves the median subject at day ",
      sprintf("%.0f", grid_days[ceiling(MAX_N_OBS / 2)]), ")")
}
sim <- sim_case_data(N_SUBJ, cp, max_n_obs = MAX_N_OBS, spacing = "log",
                     dist_n_obs = dist_n_obs, noise_sd = noise_sd)
say("visits per subject: ",
    paste(range(table(sim$id) / 2), collapse = "-"),
    " | last observation day ", sprintf("%.0f", max(sim$timeindays)))
say("data simulated | noise_sd = ", paste(attr(sim, "noise_sd"), collapse = " "),
    " | rows = ", nrow(sim), " | latent par dim = ", N_SUBJ * 10)

t0  <- Sys.time()
fit <- run_mod_stan_ch2(sim, STAN, estimate_c = 1L,
                        nchain = NCHAIN, parallel_chains = NCHAIN,
                        nadapt = WARMUP, niter = SAMP,
                        adapt_delta = ADAPT, max_treedepth = MAXTD, seed = SEED)
mins <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
say("SAMPLING DONE in ", sprintf("%.1f", mins), " min -- persisting before analysis")

# =====================================================================
# PERSIST FIRST. Nothing above this point that can throw; nothing below it can
# destroy what is already on disk.
# =====================================================================
csv_dir <- sprintf("csv_%s", TAG)
dir.create(csv_dir, showWarnings = FALSE)
ok_csv <- safe("copy csv", {
  f <- fit$output_files()
  file.copy(f, csv_dir, overwrite = TRUE)
  say("csv preserved: ", length(f), " files -> ", csv_dir); TRUE })
if (SAVE_FIT == 1L) {
  safe("save_object", { fit$save_object(sprintf("fit_%s.rds", TAG))
    say("saved fit_", TAG, ".rds"); TRUE })
} else {
  say("SAVE_FIT=0 -- skipping fit$save_object(); csv_", TAG, "/ is the archive")
}

sm <- safe("summary", fit$summary(c("mu_par", "sd_G", "sd_A", "c",
                                    "prec_logy", "cross_corr")))
ds <- safe("diagnostics", fit$diagnostic_summary())
saveRDS(list(tag = TAG, arm = ARM, summary = sm, diagnostics = ds, truth = truth,
             minutes = mins, noise_sd = attr(sim, "noise_sd"),
             n_rows = nrow(sim), latent_dim = N_SUBJ * 10, rho_scale = RHO_SCALE,
             min_n_obs = MIN_N_OBS,
             settings = list(n = N_SUBJ, max_n_obs = MAX_N_OBS, nchain = NCHAIN,
                             warmup = WARMUP, samp = SAMP, adapt_delta = ADAPT,
                             max_td = MAXTD, seed = SEED)),
        sprintf("res_%s.rds", TAG))
say("saved res_", TAG, ".rds  <-- results are now SAFE")

# =====================================================================
# ANALYSIS. Everything below is expendable.
# =====================================================================
safe("print prec_logy", { say("=== prec_logy (truth: 11.969 / 10.720) ===")
  print(fit$summary("prec_logy")) })
safe("print diagnostics", { say("=== sampler diagnostics ==="); print(ds) })

safe("convergence", {
  say("max R-hat (structural) = ", sprintf("%.4f", max(sm$rhat, na.rm = TRUE)))
  say("min ESS bulk = ", round(min(sm$ess_bulk, na.rm = TRUE)),
      " | min ESS tail = ", round(min(sm$ess_tail, na.rm = TRUE)))
  if (!is.null(ds)) {
    say("divergent total = ", sum(ds$num_divergent),
        " | treedepth-saturated = ", sum(ds$num_max_treedepth), " / ", NCHAIN * SAMP,
        sprintf(" (%.1f%%)", 100 * sum(ds$num_max_treedepth) / (NCHAIN * SAMP)))
    say("ebfmi range = ", sprintf("%.4f", min(ds$ebfmi)), " .. ",
        sprintf("%.4f", max(ds$ebfmi)))
  }
})

safe("cross_corr recovery", {
  say("=== cross_corr recovery ===")
  # FIXED: cmdstanr's default summary already carries q5 / q95.
  cc <- fit$summary("cross_corr")
  if (!all(c("q5", "q95") %in% names(cc))) {         # defensive fallback
    d <- posterior::as_draws_matrix(fit$draws("cross_corr"))
    cc$q5  <- apply(d, 2, quantile, 0.05)
    cc$q95 <- apply(d, 2, quantile, 0.95)
  }
  cc$truth   <- truth$cross_corr
  cc$covered <- cc$truth >= cc$q5 & cc$truth <= cc$q95
  cc$bias    <- cc$mean - cc$truth
  print(as.data.frame(cc[, c("variable", "mean", "q5", "q95", "rhat",
                             "truth", "bias", "covered")]), row.names = FALSE)
  say("coverage on 5 cross-correlations: ", sum(cc$covered), " / 5")
  r <- readRDS(sprintf("res_%s.rds", TAG)); r$cross_corr <- cc
  saveRDS(r, sprintf("res_%s.rds", TAG))
})

say("DONE")
