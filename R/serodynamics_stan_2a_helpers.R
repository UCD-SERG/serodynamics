#' @title Chapter 2 Stan helpers
#' @author Kwan Ho Lee
#' @description
#' Small post-processing helpers for the Chapter 2 fits: a tidy population-mean
#' summary, the two-phase antibody curve on the log scale (matching the Stan
#' `log_two_phase` and the package's [ab()]), and a Gaussian conditional
#' new-person prediction used to compare Model 2a against the independent
#' baseline.
#' @name serodynamics_stan_2a_helpers
NULL

#' @describeIn serodynamics_stan_2a_helpers Tidy posterior summary of the
#'   population means `mu_par` (one row per antigen x parameter).
#' @param fit a CmdStanR fit from [run_serodynamics_stan_2a()].
#' @param antigens optional [character] vector of antigen labels (defaults to the
#'   `"antigens"` attribute on `fit`, else `A1, A2, ...`).
#' @returns a [data.frame] with columns `antigen`, `param`, `mean`, `q5`, `q95`,
#'   `sd`, `rhat`, `ess_bulk`.
#' @export
summarise_pop_2a <- function(fit, antigens = NULL) {
  param_names <- c("log_y0", "log_y1y0", "log_t1", "log_alpha", "log_shape1")
  s <- fit$summary("mu_par")           # variable like "mu_par[k,j]"
  ka <- .parse_two_index(s$variable)   # k = antigen, j = param
  if (is.null(antigens)) antigens <- attr(fit, "antigens")
  n_ant <- max(ka$i)
  if (is.null(antigens) || length(antigens) != n_ant) {
    antigens <- paste0("A", seq_len(n_ant))
  }
  data.frame(
    antigen  = antigens[ka$i],
    param    = param_names[ka$j],
    mean     = s$mean,
    q5       = s$q5,
    q95      = s$q95,
    sd       = s$sd,
    rhat     = s$rhat,
    ess_bulk = s$ess_bulk,
    stringsAsFactors = FALSE
  )
}

#' @describeIn serodynamics_stan_2a_helpers Two-phase antibody curve on the log
#'   scale (identical to the Stan `log_two_phase`).
#' @param t numeric vector of times.
#' @param log_y0,log_y1 log baseline and log peak.
#' @param t1 time to peak.
#' @param alpha decay rate.
#' @param shape decay shape `r` (`> 1`).
#' @returns numeric vector `log y(t)`.
#' @export
log_two_phase_r <- function(t, log_y0, log_y1, t1, alpha, shape) {
  y1 <- exp(log_y1)
  a  <- shape - 1
  ifelse(
    t <= t1,
    log_y0 + (log_y1 - log_y0) / t1 * t,
    log_y1 - log1p(a * alpha * (t - t1) * y1^a) / a
  )
}

#' @describeIn serodynamics_stan_2a_helpers Conditional new-person prediction.
#'   Given posterior draws of the joint population mean and covariance, predict
#'   the log curve parameters of one biomarker (`predict_antigen`) for a new
#'   subject, optionally CONDITIONING on observed log parameters of the other
#'   biomarker (`given`). With cross-biomarker covariance (Model 2a) the
#'   conditioning tightens the prediction; with a block-diagonal covariance
#'   (independent) it does not. Returns posterior-predictive draws of that
#'   biomarker's 5 log parameters, which you can push through
#'   [log_two_phase_r()] to get curve credible intervals.
#'
#' @param mu_draws matrix `[ndraws, n_total]` of population-mean draws (stacked
#'   as antigen-major: antigen 1's 5 params, then antigen 2's 5).
#' @param Sigma_draws array `[ndraws, n_total, n_total]` of joint covariance
#'   draws (use a block-diagonal Sigma for the independent baseline).
#' @param predict_antigen index (1 or 2) of the biomarker to predict.
#' @param given optional named or positional length-5 vector of observed log
#'   parameters for the OTHER biomarker (NULL = marginal prediction).
#' @param n_params number of curve parameters (default 5).
#' @returns matrix `[ndraws, n_params]` of predicted log parameters for the new
#'   subject's `predict_antigen`.
#' @export
predict_newperson_2a <- function(mu_draws, Sigma_draws,
                                 predict_antigen = 2L,
                                 given = NULL,
                                 n_params = 5L) {
  ndraws <- nrow(mu_draws)
  p <- n_params
  pred_idx <- ((predict_antigen - 1L) * p + 1L):(predict_antigen * p)
  other_antigen <- if (predict_antigen == 1L) 2L else 1L
  other_idx <- ((other_antigen - 1L) * p + 1L):(other_antigen * p)

  out <- matrix(NA_real_, ndraws, p)
  for (d in seq_len(ndraws)) {
    mu <- mu_draws[d, ]
    S  <- Sigma_draws[d, , ]
    mu_p <- mu[pred_idx]
    S_pp <- S[pred_idx, pred_idx, drop = FALSE]
    if (is.null(given)) {
      # marginal new-person draw for the predicted biomarker
      out[d, ] <- .rmvn1(mu_p, S_pp)
    } else {
      mu_o <- mu[other_idx]
      S_oo <- S[other_idx, other_idx, drop = FALSE]
      S_po <- S[pred_idx, other_idx, drop = FALSE]
      # Gaussian conditional: mu_p + S_po S_oo^-1 (given - mu_o),
      #                        S_pp - S_po S_oo^-1 S_op
      W <- S_po %*% solve(S_oo)
      cond_mu <- as.numeric(mu_p + W %*% (as.numeric(given) - mu_o))
      cond_S  <- S_pp - W %*% t(S_po)
      cond_S  <- (cond_S + t(cond_S)) / 2          # symmetrize
      out[d, ] <- .rmvn1(cond_mu, cond_S)
    }
  }
  out
}

# ---- internals -------------------------------------------------------------

# Parse "name[i,j]" -> list(i=..., j=...)
.parse_two_index <- function(x) {
  m <- regmatches(x, regexec("\\[(\\d+),(\\d+)\\]", x))
  i <- vapply(m, function(z) as.integer(z[2]), integer(1))
  j <- vapply(m, function(z) as.integer(z[3]), integer(1))
  list(i = i, j = j)
}

# One draw from MVN(mu, S) via Cholesky (with a tiny jitter fallback).
.rmvn1 <- function(mu, S) {
  L <- tryCatch(chol(S), error = function(e) {
    chol(S + diag(1e-8, nrow(S)))
  })
  as.numeric(mu + t(L) %*% stats::rnorm(length(mu)))
}
