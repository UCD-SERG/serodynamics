#!/usr/bin/env Rscript
# =====================================================================
# harness_dryrun.R -- exercise the REAL pipeline code without Stan/serodynamics.
#
# Stubs only the package leaf functions (ab, as_case_data, the biomarker
# accessors, sim_n_obs, sim_obs_times).  Everything under test -- the whole of
# make_corr_curve_params.R and sim_case_data.R -- is the actual file that ships
# to Mercury.  Catches plumbing and logic errors before they cost a server
# round-trip.  Cannot test sampler behaviour (R-hat, divergences, runtime);
# that is irreducibly Mercury's job.
# =====================================================================
suppressPackageStartupMessages({ library(dplyr); library(tibble) })

# ---- stubs: package leaf functions -----------------------------------------
# Two-phase antibody curve, matching model_ch2.stan two_phase_logk():
#   growth  t <= t1 : log y = log y0 + (log y1 - log y0) * t / t1
#   decay   t >  t1 : log y = log y1 - log1p(a*alpha*(t-t1)*y1^a) / a,  a = r-1
ab <- function(t, y0, y1, t1, alpha, shape) {
  a <- shape - 1
  ly0 <- log(y0); ly1 <- log(y1)
  out <- ifelse(t <= t1,
                ly0 + (ly1 - ly0) * t / t1,
                ly1 - log1p(a * alpha * pmax(t - t1, 0) * y1^a) / a)
  exp(out)
}
sim_n_obs <- function(dist_n_obs, n)
  sample(dist_n_obs$n_obs, n, replace = TRUE, prob = dist_n_obs$prob)
sim_obs_times <- function(followup_interval, followup_variance, n_obs, spacing,
                          max_n_obs, t_min, t_max) {
  if (spacing == "log") exp(seq(log(t_min), log(t_max), length.out = max_n_obs))[seq_len(n_obs)]
  else cumsum(c(0, round(rnorm(n_obs - 1, followup_interval, followup_variance))))
}
as_case_data <- function(df, id_var, biomarker_var, time_in_days, value_var) {
  structure(df, class = c("case_data", class(df)),
            id_var = id_var, biomarker_var = biomarker_var)
}
get_biomarker_levels    <- function(x) unique(as.character(x[[attr(x, "biomarker_var")]]))
get_biomarker_names     <- function(x) get_biomarker_levels(x)
get_biomarker_names_var <- function(x) attr(x, "biomarker_var")

# ---- code under test: the ACTUAL files -------------------------------------
source("make_corr_curve_params.R")
source("sim_case_data.R")

TG <- readRDS("/mnt/user-data/outputs/ch2_truth_targets.rds")
RHO <- as.numeric(TG$cross_corr_median)
NS  <- c(0.2890, 0.3054)
pass <- 0L; fail <- 0L
chk <- function(label, ok, detail = "") {
  if (isTRUE(ok)) { pass <<- pass + 1L; cat(sprintf("  PASS  %-52s %s\n", label, detail)) }
  else            { fail <<- fail + 1L; cat(sprintf("  FAIL  %-52s %s\n", label, detail)) }
}

cat("=== 1. make_corr_curve_params: mathematical guarantees ===\n")
set.seed(1)
cp <- make_corr_curve_params(4000, targets = TG, rho = RHO, constructor = "manual")
tr <- attr(cp, "truth"); P <- 5L; Sf <- tr$Sigma_full
cc <- sapply(1:P, function(j) Sf[j, P + j] / sqrt(Sf[j, j] * Sf[P + j, P + j]))
chk("injected rho == model-scale cross_corr", max(abs(cc - RHO)) < 1e-12,
    sprintf("max|gap|=%.2e", max(abs(cc - RHO))))
chk("Sigma_G recovered exactly", max(abs(Sf[1:P, 1:P] - TG$Sigma_G)) < 1e-12)
chk("marginal Sigma_A preserved under rho", max(abs(Sf[(P+1):(2*P), (P+1):(2*P)] - TG$Sigma_A)) < 1e-12)
chk("all curve params finite and positive",
    all(is.finite(cp$y0)) && all(cp$y0 > 0) && all(cp$y1 > cp$y0) && all(cp$r > 1))
cp0 <- make_corr_curve_params(1000, targets = TG, rho = rep(0, 5), constructor = "manual")
chk("nesting: rho=0 gives exactly zero cross block",
    max(abs(attr(cp0, "truth")$Sigma_full[1:P, (P+1):(2*P)])) == 0)
bad <- tryCatch({ make_corr_curve_params(10, targets = TG, rho = rep(0.8, 5),
                                         constructor = "manual"); FALSE },
                error = function(e) TRUE)
chk("inadmissible rho raises an error", bad)

cat("\n=== 2. log_k -> log_alpha back-transform ===\n")
set.seed(2)
cpk <- make_corr_curve_params(3000, targets = TG, rho = RHO, constructor = "manual")
G   <- cpk[cpk$antigen_iso == "HlyE_IgG", ]
lk  <- log(G$alpha) + (G$r - 1) * log(G$y1)     # invert: log_k = log_alpha + (r-1)log y1
chk("recovered log_k mean matches mu_G[4]", abs(mean(lk) - TG$mu_G[4]) < 0.05,
    sprintf("%.4f vs %.4f", mean(lk), TG$mu_G[4]))
chk("recovered log_k sd matches sqrt(Sigma_G[4,4])",
    abs(sd(lk) - sqrt(TG$Sigma_G[4, 4])) < 0.05,
    sprintf("%.4f vs %.4f", sd(lk), sqrt(TG$Sigma_G[4, 4])))

cat("\n=== 3. sim_case_data: noise behaviour ===\n")
set.seed(7); s0 <- sim_case_data(80, cp, max_n_obs = 20, spacing = "log")
set.seed(7); s1 <- sim_case_data(80, cp, max_n_obs = 20, spacing = "log", noise_sd = NS)
stopifnot(all(c("id", "timeindays", "iter") %in% names(s0)))   # column names really exist
chk("noise_sd=0 consumes no RNG (identical skeleton)",
    identical(s0$id, s1$id) && identical(s0$timeindays, s1$timeindays) &&
      identical(s0$iter, s1$iter) && identical(s0$t1, s1$t1),
    sprintf("id/timeindays/iter/t1 identical over %d rows", nrow(s0)))
chk("attr(noise_sd) recorded", isTRUE(all.equal(unname(attr(s1, "noise_sd")), NS)))
chk("all noisy values strictly positive (no log(NaN) downstream)",
    all(is.finite(s1$value)) && all(s1$value > 0))
lr <- log(s1$value) - log(s0$value)
sdG <- sd(lr[s1$antigen_iso == "HlyE_IgG"]); sdA <- sd(lr[s1$antigen_iso == "HlyE_IgA"])
chk("per-antigen noise SD on the LOG scale is correct",
    abs(sdG - NS[1]) < 0.03 && abs(sdA - NS[2]) < 0.03,
    sprintf("IgG %.4f (want %.4f) | IgA %.4f (want %.4f)", sdG, NS[1], sdA, NS[2]))
chk("noise is multiplicative, not additive (log ratio ~ constant across level)",
    abs(cor(lr, log(s0$value))) < 0.10,
    sprintf("cor(log ratio, log level) = %+.4f", cor(lr, log(s0$value))))
set.seed(9); a <- sim_case_data(40, cp, max_n_obs = 10, spacing = "log")
set.seed(9); b <- sim_case_data(40, cp, max_n_obs = 10, spacing = "log", noise_sd = 0)
chk("noise_sd=0 reproduces the no-argument call bit-for-bit",
    identical(a$value, b$value))
e1 <- tryCatch({ sim_case_data(5, cp, noise_sd = c(-1, 1)); FALSE }, error = function(e) TRUE)
e2 <- tryCatch({ sim_case_data(5, cp, noise_sd = c(1, 2, 3)); FALSE }, error = function(e) TRUE)
chk("rejects negative noise_sd", e1); chk("rejects wrong-length noise_sd", e2)

cat(sprintf("\n================  %d passed, %d failed  ================\n", pass, fail))
if (fail > 0) quit(status = 1)
