# =====================================================================
# ch2_sim_functions.R  --  shared helpers for the Chapter-2 recovery study
# (Ezra's metric: bias / MSE / posterior variance / coverage on the model
# parameters, from a simulation with a KNOWN cross-correlation).
#
# Sourced by ch2_sim_one.R, ch2_recovery_metrics.R, ch2_recovery_plots.R.
# Depends only on base R here; the simulation/fit scripts load serodynamics.
#
# --------------------------------------------------------------------
# CHANGES IN THIS VERSION
#   1. scenario_truth(): gains an EXACT analytic path. When curve_params comes
#      from the rewritten make_corr_curve_params() (log_k scale), the truth is
#      known in closed form and the 400k-draw Monte Carlo is only a check.
#   2. sim_ch2_clustered(): the `noise_sd` argument existed but added noise on
#      the NATURAL scale; the models add it on the LOG scale. Fixed, and made
#      per-antigen.
# =====================================================================

# ---- model-scale parameter order (what the Stan model estimates) ----
#   slot: 1=log_y0  2=log_y1y0  3=log_t1  4=log_k  5=log_shape1
# The rewritten make_corr_curve_params() injects directly on this scale, so the
# injected rho IS the model-scale cross-correlation and scenario_truth() can
# return it in closed form.  The LEGACY version injected on the log_ALPHA scale
# (slot 4 = log_alpha) while the model samples log_k = log_alpha + (r-1)*log(y1);
# for that case the truth still has to be computed empirically by Monte Carlo.

PARAM_LABELS <- c("baseline", "peak", "peak-time", "decay-rate", "decay-shape")  # slots 1..5

# ---------------------------------------------------------------------
# scenario_truth(): MODEL-scale truth for one scenario.
#
#   Preferred call (exact, no Monte Carlo):
#     scenario_truth(curve_params = cp)
#   where cp came from make_corr_curve_params(..., param_scale = "log_k").
#   Set verify = TRUE to additionally run the Monte Carlo and report the gap.
#
#   Legacy call (Monte Carlo, log_alpha injection scale):
#     scenario_truth(mu_G, mu_A, sd_G, sd_A, rho)
#
#   Returns mu_par[antigen, slot], sd[antigen, slot], cross_corr[slot].
# ---------------------------------------------------------------------
scenario_truth <- function(mu_G = NULL, mu_A = NULL, sd_G = NULL, sd_A = NULL,
                           rho = NULL, curve_params = NULL,
                           Sigma_G = NULL, Sigma_A = NULL,
                           param_scale = c("log_alpha", "log_k"),
                           n_iter = 400000L, seed = 20240101L,
                           verify = FALSE) {
  P <- 5L
  param_scale <- match.arg(param_scale)

  # ---- ADDED: exact path -------------------------------------------------
  tr <- if (!is.null(curve_params)) attr(curve_params, "truth") else NULL
  if (!is.null(tr) && identical(tr$param_scale, "log_k")) {
    Sf <- tr$Sigma_full
    mu_par <- rbind(IgG = tr$mu_G, IgA = tr$mu_A)
    sdm    <- rbind(IgG = tr$sd_G, IgA = tr$sd_A)
    cc     <- vapply(seq_len(P), function(j)
      Sf[j, P + j] / sqrt(Sf[j, j] * Sf[P + j, P + j]), numeric(1))
    out <- list(mu_par = mu_par, sd = sdm, cross_corr = cc,
                labels = PARAM_LABELS, source = "analytic",
                inputs = list(mu_G = tr$mu_G, mu_A = tr$mu_A,
                              Sigma_G = tr$Sigma_G, Sigma_A = tr$Sigma_A,
                              rho = tr$rho))
    if (!isTRUE(verify)) return(out)
    # optional Monte-Carlo cross-check of the analytic truth
    set.seed(seed)
    Q <- 2L * P
    z <- matrix(rnorm(Q * n_iter), Q, n_iter)
    M <- t(tr$mu_flat + tr$L_full %*% z)
    cc_mc <- vapply(seq_len(P), function(j) cor(M[, j], M[, P + j]), numeric(1))
    out$mc_check <- list(cross_corr = cc_mc,
                         max_abs_gap = max(abs(cc_mc - cc)))
    return(out)
  }

  # ---- legacy path: Monte Carlo on the log_alpha injection scale ----------
  if (is.null(Sigma_G) && !is.null(sd_G)) Sigma_G <- diag(as.numeric(sd_G)^2, P)
  if (is.null(Sigma_A) && !is.null(sd_A)) Sigma_A <- diag(as.numeric(sd_A)^2, P)
  stopifnot(length(mu_G) == P, length(mu_A) == P, length(rho) == P,
            !is.null(Sigma_G), !is.null(Sigma_A))
  sdG <- sqrt(diag(Sigma_G)); sdA <- sqrt(diag(Sigma_A))

  set.seed(seed)
  logG <- matrix(NA_real_, n_iter, P); logA <- matrix(NA_real_, n_iter, P)
  for (k in seq_len(P)) {
    S <- matrix(c(sdG[k]^2, rho[k] * sdG[k] * sdA[k],
                  rho[k] * sdG[k] * sdA[k], sdA[k]^2), 2, 2)
    L <- chol(S)
    z <- matrix(rnorm(2 * n_iter), 2, n_iter)
    v <- c(mu_G[k], mu_A[k]) + t(L) %*% z
    logG[, k] <- v[1, ]; logA[, k] <- v[2, ]
  }
  # map injection scale -> MODEL scale (slot 4: log_alpha -> log_k)
  to_model <- function(M) {
    log_y0 <- M[, 1]; log_y1y0 <- M[, 2]; log_t1 <- M[, 3]
    log_alpha <- M[, 4]; log_shape1 <- M[, 5]
    log_y1 <- log(exp(log_y0) + exp(log_y1y0))
    r <- 1 + exp(log_shape1)
    log_k <- log_alpha + (r - 1) * log_y1
    cbind(log_y0, log_y1y0, log_t1, log_k, log_shape1)
  }
  MG <- to_model(logG); MA <- to_model(logA)
  list(mu_par = rbind(IgG = colMeans(MG), IgA = colMeans(MA)),
       sd     = rbind(IgG = apply(MG, 2, sd), IgA = apply(MA, 2, sd)),
       cross_corr = vapply(seq_len(P), function(k) cor(MG[, k], MA[, k]), numeric(1)),
       labels = PARAM_LABELS, source = "monte_carlo",
       inputs = list(mu_G = mu_G, mu_A = mu_A, Sigma_G = Sigma_G,
                     Sigma_A = Sigma_A, rho = rho))
}

# ---------------------------------------------------------------------
# make_clustered_schedule(): Ezra's clustered sampling -- resample real Nepal
#   visit-day vectors, one subject at a time, with replacement.  Returns a list
#   of numeric visit-day vectors (length n_subj).
#   df = nepal_sees (columns id + time). time defaults to dayssincefeveronset.
# ---------------------------------------------------------------------
make_clustered_schedule <- function(df, n_subj, seed = 1L,
                                    id_col = "id", time_col = "dayssincefeveronset",
                                    min_visits = 2L) {
  vl <- tapply(df[[time_col]], df[[id_col]], function(d) sort(unique(d)))
  vl <- vl[lengths(vl) >= min_visits]
  set.seed(seed)
  idx <- sample(seq_along(vl), size = n_subj, replace = TRUE)  # per-subject cluster resample
  unname(vl[idx])
}

# ---------------------------------------------------------------------
# recovery_metrics(): given per-seed fit summaries (mean, q5, q95, sd) for one
#   parameter under one model, and the truth, return bias/MSE/post_var/coverage.
#   est_mean, q5, q95, post_sd are numeric vectors over seeds.
# ---------------------------------------------------------------------
recovery_metrics <- function(est_mean, q5, q95, post_sd, truth) {
  keep <- is.finite(est_mean)
  em <- est_mean[keep]; lo <- q5[keep]; hi <- q95[keep]; ps <- post_sd[keep]
  c(bias     = mean(em) - truth,
    mse      = mean((em - truth)^2),
    post_var = mean(ps^2),
    coverage = mean(truth >= lo & truth <= hi),
    n_seed   = length(em))
}

# ---------------------------------------------------------------------
# extract_fit_summary(): pull a compact per-parameter summary from a fitted
#   model (mu_par[antigen,slot] + cross_corr[slot]).  Returns a data frame with
#   columns: kind, antigen, slot, label, mean, q5, q95, sd, rhat.
#   Works for both Ch2 (cross_corr free) and Ch1 (cross_corr == 0).
# ---------------------------------------------------------------------
extract_fit_summary <- function(fit) {
  s <- fit$summary(c("mu_par", "cross_corr"))
  rows <- list()
  for (a in 1:2) for (j in 1:5) {
    v <- sprintf("mu_par[%d,%d]", a, j)
    r <- s[s$variable == v, ]
    rows[[length(rows) + 1]] <- data.frame(
      kind = "mu_par", antigen = c("IgG", "IgA")[a], slot = j, label = PARAM_LABELS[j],
      mean = r$mean, q5 = r$q5, q95 = r$q95, sd = r$sd,
      rhat = if ("rhat" %in% names(r)) r$rhat else NA_real_)
  }
  for (j in 1:5) {
    v <- sprintf("cross_corr[%d]", j)
    r <- s[s$variable == v, ]
    if (nrow(r) == 0) {   # Ch1 with estimate_c=0 may not report it -> structural 0
      rows[[length(rows) + 1]] <- data.frame(
        kind = "cross_corr", antigen = "IgG-IgA", slot = j, label = PARAM_LABELS[j],
        mean = 0, q5 = 0, q95 = 0, sd = 0, rhat = NA_real_)
    } else {
      rows[[length(rows) + 1]] <- data.frame(
        kind = "cross_corr", antigen = "IgG-IgA", slot = j, label = PARAM_LABELS[j],
        mean = r$mean, q5 = r$q5, q95 = r$q95, sd = r$sd,
        rhat = if ("rhat" %in% names(r)) r$rhat else NA_real_)
    }
  }
  do.call(rbind, rows)
}

# ---------------------------------------------------------------------
# sim_ch2_clustered(): generate Chapter-2 data on REAL (clustered) visit
#   schedules -- Ezra's ask ("sample the visit dates, one person at a time").
#   Each simulated subject gets ONE joint (IgG+IgA) parameter draw (so the two
#   isotypes are correlated) evaluated at ONE resampled real visit-day vector.
#   Uses the package curve `ab()` and `as_case_data()` (load serodynamics first).
#
#   curve_params : from make_corr_curve_params() (correlated draws)
#   schedules    : list of numeric visit-day vectors (from make_clustered_schedule)
#   noise_sd     : measurement-error SD ON THE LOG SCALE, length 1 or one per
#                  antigen_iso.  c(0.2890, 0.3054) matches the nepal_sees fit
#                  (prec_logy = 11.969 / 10.720).
#
#   CHANGED: the previous version did `val <- val + rnorm(length(val), 0, noise_sd)`,
#   i.e. additive noise on the NATURAL scale.  Both models put the noise on the
#   LOG scale (model.jags L54, model_ch2.stan L110).  The old form inverted the
#   error structure (a log-scale SD of 0.29 is ~29% everywhere; adding 0.29 to
#   the natural value is ~29% at baseline and ~0.2% at peak) and could return
#   negative values, which become NaN at prep_ch2_standata() L49 `log(value)`.
# ---------------------------------------------------------------------
sim_ch2_clustered <- function(curve_params, schedules,
                              antigen_isos = c("HlyE_IgG", "HlyE_IgA"),
                              id_prefix = "sim", noise_sd = 0) {
  stopifnot(is.list(schedules), length(schedules) >= 1)
  bio_col <- attr(curve_params, "biomarker_var"); if (is.null(bio_col)) bio_col <- "antigen_iso"

  # ---- ADDED: align noise_sd to antigen_isos -----------------------------
  noise_sd <- as.numeric(noise_sd)
  if (any(!is.finite(noise_sd)) || any(noise_sd < 0))
    stop("`noise_sd` must be finite and non-negative.")
  if (length(noise_sd) == 1L) {
    noise_vec <- rep(noise_sd, length(antigen_isos))
  } else if (length(noise_sd) == length(antigen_isos)) {
    noise_vec <- noise_sd
  } else {
    stop(sprintf("`noise_sd` must have length 1 or %d; got %d.",
                 length(antigen_isos), length(noise_sd)))
  }
  names(noise_vec) <- antigen_isos

  iters  <- unique(curve_params$iter)
  n_subj <- length(schedules)
  chosen <- sample(iters, n_subj, replace = TRUE)   # one joint draw per subject

  per_subj <- lapply(seq_len(n_subj), function(s) {
    it <- chosen[s]; days <- schedules[[s]]; sid <- sprintf("%s_%d", id_prefix, s)
    do.call(rbind, lapply(antigen_isos, function(iso) {
      cp  <- curve_params[curve_params$iter == it & curve_params[[bio_col]] == iso, ][1, ]
      val <- ab(t = days, y0 = cp$y0, y1 = cp$y1, t1 = cp$t1, alpha = cp$alpha, shape = cp$r)
      # CHANGED: multiplicative on the natural scale == additive on the log scale
      sdk <- unname(noise_vec[iso])
      if (sdk > 0) val <- val * exp(rnorm(length(val), 0, sdk))
      data.frame(id = sid, antigen_iso = iso, timeindays = days, value = val,
                 stringsAsFactors = FALSE)
    }))
  })
  df  <- do.call(rbind, per_subj)
  out <- as_case_data(df, id_var = "id", biomarker_var = "antigen_iso",
                      time_in_days = "timeindays", value_var = "value")
  attr(out, "noise_sd") <- noise_vec   # ADDED: record what was simulated
  out
}
