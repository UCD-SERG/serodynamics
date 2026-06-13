#' @title Simulate subject-level parameters with a known Model 2a covariance
#' @description
#' Draws `n` subjects' log-scale kinetic parameters for **two** biomarkers from
#' a Model 2a multivariate normal: full within-biomarker blocks `Sigma_G`,
#' `Sigma_A` plus a diagonal cross-biomarker block `C = diag(c_vec)` (assembled
#' by [build_sigma_2a()]). This gives ground-truth correlated parameters for
#' validating [run_mod_2a()].
#'
#' The parameter order matches `model.jags`:
#' 1 = log(y0), 2 = log(y1 - y0), 3 = log(t1), 4 = log(alpha),
#' 5 = log(shape - 1). Uses a base-R Cholesky draw (no extra dependency).
#'
#' @param n [integer] number of subjects.
#' @param mu_g,mu_a Length-`P` log-scale mean vectors for biomarker 1 / 2.
#' @param sigma_g,sigma_a `P x P` within-biomarker covariances.
#' @param c_vec Length-`P` same-parameter cross-biomarker covariances.
#' @param seed Optional RNG seed.
#'
#' @returns A [list] with:
#'   - `log_par`: an `n x (2P)` [matrix] of draws, columns ordered
#'     `G1..GP, A1..AP`;
#'   - `sigma`: the `2P x 2P` true covariance;
#'   - `rho`: the length-`P` true cross-biomarker correlations.
#' @export
sim_params_2a <- function(n, mu_g, mu_a, sigma_g, sigma_a, c_vec,
                          seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  p <- length(mu_g)
  sigma <- build_sigma_2a(sigma_g, sigma_a, c_vec)
  mu <- c(mu_g, mu_a)

  z <- matrix(stats::rnorm(n * 2 * p), nrow = n)
  log_par <- z %*% chol(sigma)
  log_par <- sweep(log_par, 2, mu, "+")

  rho <- c_vec / sqrt(diag(sigma_g) * diag(sigma_a))
  list(log_par = log_par, sigma = sigma, rho = rho)
}
