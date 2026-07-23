#!/usr/bin/env Rscript
# =====================================================================
# ch2_sim_one.R  --  ONE (scenario, seed) of the Chapter-2 recovery study.
#   1. build known-c correlated curve_params  (make_corr_curve_params, rho = c_true)
#   2. simulate Chapter-2 data                (sim_case_data, model = "ch2")
#   3. fit BOTH models                        (run_mod_stan_ch2, estimate_c = 1 and 0)
#   4. extract per-parameter summaries        (extract_fit_summary)
#   5. save a compact CSV tagged scenario/seed/model
#
# Driven by run_ch2_sim_mercury.sh via env vars.  Truth is computed separately
# (ch2_recovery_metrics.R) from the same scenario inputs -- it does NOT depend on
# this fit, so it is exact.
#
#   SCENARIO=medium RHO="0,0.6,0.87,0.76,0.35" SIM_N=500 SIM_SEED=1 \
#     SPACING=log MAX_N_OBS=15 T_MIN=3 T_MAX=400 WHICH=both Rscript ch2_sim_one.R
# =====================================================================
suppressPackageStartupMessages({ library(cmdstanr) })

PKG <- Sys.getenv("PKG_DIR", ".")            # serodynamics package root (for load_all)
if (requireNamespace("devtools", quietly = TRUE)) {
  suppressMessages(devtools::load_all(PKG, quiet = TRUE))
} else {
  suppressPackageStartupMessages(library(serodynamics))
}
# make_corr_curve_params is base-R self-contained; source if the package build lacks it
if (!exists("make_corr_curve_params")) source("make_corr_curve_params.R")
source("stan_ch2_functions.R")               # run_mod_stan_ch2, prep_*
source("ch2_sim_functions.R")                # extract_fit_summary, make_clustered_schedule

## ---- scenario / run settings (env) ----
SCEN   <- Sys.getenv("SCENARIO", "medium")
RHO    <- as.numeric(strsplit(Sys.getenv("RHO", "0,0.6,0.87,0.76,0.35"), ",")[[1]])
stopifnot(length(RHO) == 5)
SEED   <- as.integer(Sys.getenv("SIM_SEED", "1"))
N      <- as.integer(Sys.getenv("SIM_N", "500"))
MNO    <- as.integer(Sys.getenv("MAX_N_OBS", "15"))
SPACING<- Sys.getenv("SPACING", "log")       # "log" | "uniform" | "clustered" (real Nepal visit dates)
TMIN   <- as.numeric(Sys.getenv("T_MIN", "3"))
TMAX   <- as.numeric(Sys.getenv("T_MAX", "400"))
FUP_I  <- as.integer(Sys.getenv("FUP_INTERVAL", "21"))
FUP_V  <- as.integer(Sys.getenv("FUP_VARIANCE", "1"))
WHICH  <- Sys.getenv("WHICH", "both")        # "both" | "ch1" | "ch2"
NITERCP<- as.integer(Sys.getenv("CP_N_ITER", "4000"))

## ---- population truth inputs (log scale; slot 4 = log_alpha) ----
# Defaults are Shigella/typhoid-like; override via env if needed.
mu_G <- as.numeric(strsplit(Sys.getenv("MU_G", "0.8,5.1,2.2,-7.1,-0.9"), ",")[[1]])
mu_A <- as.numeric(strsplit(Sys.getenv("MU_A", "0.7,4.2,1.6,-7.1,-0.4"), ",")[[1]])
sd_G <- as.numeric(strsplit(Sys.getenv("SD_G", "0.3,0.3,0.2,0.5,0.4"), ",")[[1]])
sd_A <- as.numeric(strsplit(Sys.getenv("SD_A", "0.3,0.4,0.3,0.5,0.4"), ",")[[1]])

## ---- Stan settings (env; keep modest per fit, many seeds give the SE) ----
CHAINS <- as.integer(Sys.getenv("STAN_CHAINS", "4"))
WARMUP <- as.integer(Sys.getenv("STAN_WARMUP", "1500"))
SAMP   <- as.integer(Sys.getenv("STAN_SAMP", "1500"))
ADAPT  <- as.numeric(Sys.getenv("ADAPT_DELTA", "0.99"))
MAXTD  <- as.integer(Sys.getenv("MAX_TD", "14"))
CSD    <- as.numeric(Sys.getenv("C_PRIOR_SD", "1.0"))
STAN   <- Sys.getenv("MODEL_STAN", "model_ch2.stan"); stopifnot(file.exists(STAN))

cat(sprintf("[sim] scenario=%s seed=%d n=%d mno=%d spacing=%s rho=(%s)\n",
            SCEN, SEED, N, MNO, SPACING, paste(RHO, collapse=",")))

## ---- 1. known-c correlated curve_params ----
set.seed(SEED)
cp <- make_corr_curve_params(n_iter = NITERCP, mu_G = mu_G, mu_A = mu_A,
                             sd_G = sd_G, sd_A = sd_A, rho = RHO)

## ---- 2. simulate Chapter-2 data ----
if (SPACING == "clustered") {
  # Ezra's realistic scenario: resample REAL Nepal visit-day vectors, one subject
  # at a time (clustered sampling), and evaluate the correlated curves on them.
  data("nepal_sees", package = "serodynamics"); nd <- get("nepal_sees")
  sched <- make_clustered_schedule(nd, n_subj = N, seed = SEED)   # vary WHERE visits fall
  sim <- sim_ch2_clustered(cp, sched)
  cat(sprintf("[sim] CLUSTERED (real Nepal visit dates): %d rows, %d subjects, visits/subj %d-%d\n",
              nrow(sim), length(unique(sim$id)), min(lengths(sched)), max(lengths(sched))))
} else {
  # correlation comes from the (correlated) curve_params -- the package sim_case_data
  # samples ONE iter per subject and joins BOTH isotypes from that iter, so IgG/IgA
  # stay correlated.  Pass model="ch2" only if this build's sim_case_data accepts it.
  sc_args <- list(cp, n = N, max_n_obs = MNO, spacing = SPACING,
                  t_min = TMIN, t_max = TMAX,
                  followup_interval = FUP_I, followup_variance = FUP_V)
  if ("model" %in% names(formals(sim_case_data))) sc_args$model <- "ch2"
  sim <- do.call(sim_case_data, sc_args)
  cat(sprintf("[sim] %s spacing: %d rows, %d subjects\n",
              SPACING, nrow(sim), length(unique(sim$id))))
}

## ---- 3. fit requested model(s) + 4. extract + 5. save ----
fit_and_save <- function(which_model) {
  ec <- if (which_model == "ch2") 1L else 0L
  wu <- if (which_model == "ch1") max(WARMUP, 2000L) else WARMUP   # Ch1 a touch more warmup
  fit <- run_mod_stan_ch2(
    data = sim, file_mod = STAN, estimate_c = ec, min_visits = 2L,
    nchain = CHAINS, parallel_chains = CHAINS,
    nadapt = wu, niter = SAMP, adapt_delta = ADAPT, max_treedepth = MAXTD,
    c_prior_sd = CSD, init = 0.3, seed = SEED)
  sm <- extract_fit_summary(fit)
  sm$scenario <- SCEN; sm$seed <- SEED; sm$model <- which_model
  sm$max_rhat_fit <- tryCatch(max(fit$summary(c("mu_par","cross_corr"))$rhat, na.rm=TRUE),
                              error=function(e) NA_real_)
  out <- sprintf("sim_%s_%s_seed%d.csv", SCEN, which_model, SEED)
  write.csv(sm, out, row.names = FALSE)
  cat(sprintf("[sim] saved %s  (max Rhat %.3f)\n", out, sm$max_rhat_fit[1]))
}

if (WHICH %in% c("both","ch2")) fit_and_save("ch2")
if (WHICH %in% c("both","ch1")) fit_and_save("ch1")
cat("[sim] DONE\n")
