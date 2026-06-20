#' @title Validate the Chapter 1 nesting / no-false-positive behaviour
#' @description
#' Complementary check to [validate_recovery_2a()]. It simulates **independent**
#' two-biomarker data (all cross-biomarker covariances `c_vec = 0`, i.e. the
#' Chapter 1 truth) and confirms that Model 2a does **not** invent
#' cross-biomarker correlation: every posterior `c_p` credible interval should
#' cover zero. This is the empirical counterpart of the algebraic fact that
#' `lambda = 0` reduces Model 2a to Chapter 1.
#'
#' The packaged typhoid simulator [sim_case_data()] also produces independent
#' biomarkers, so fitting Model 2a to its output is an equivalent
#' real-data-style null check.
#'
#' @param n [integer] number of subjects. Default `120`.
#' @param mu_g,mu_a,sigma_g,sigma_a Model 2a truth (cross-block forced to zero).
#' @param noise_sd Residual SD on the log scale. Default `0.15`.
#' @param seed RNG seed. Default `1`.
#' @param ... MCMC controls forwarded to [run_mod_2a()].
#'
#' @returns A [data.frame] with columns `param`, `cov_med`, `cov_lo`, `cov_hi`,
#'   and `covers_zero` ([logical]); all rows should have `covers_zero = TRUE`.
#' @export
validate_nesting_2a <- function(
    n = 120,
    mu_g = c(0.0, 3.0, 2.3, -4.0, -1.0),
    mu_a = c(0.2, 3.1, 2.2, -3.8, -1.1),
    sigma_g = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
    sigma_a = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
    noise_sd = 0.15,
    seed = 1,
    ...) {
  c_zero <- rep(0, length(mu_g))
  sim <- sim_case_data_2a(
    n = n, mu_g = mu_g, mu_a = mu_a,
    sigma_g = sigma_g, sigma_a = sigma_a, c_vec = c_zero,
    noise_sd = noise_sd, seed = seed
  )
  fit <- run_mod_2a(sim$data, ...)
  out <- fit$cross[, c("param", "cov_med", "cov_lo", "cov_hi")]
  out$covers_zero <- out$cov_lo <= 0 & out$cov_hi >= 0
  out
}
