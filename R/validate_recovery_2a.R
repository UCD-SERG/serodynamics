#' @title Validate Model 2a parameter recovery
#' @description
#' Simulation-based check that [run_mod_2a()] recovers a **known**
#' cross-biomarker correlation. It simulates two-biomarker longitudinal data
#' with a chosen `c_vec` ([sim_case_data_2a()]), fits Model 2a, and returns a
#' table comparing the true cross-biomarker correlation with the posterior
#' estimate per kinetic parameter.
#'
#' Recovery is expected to be accurate for well-identified parameters (peak,
#' decay) and to attenuate gracefully for weakly-identified ones (baseline);
#' true nulls should yield credible intervals covering zero.
#'
#' @param n [integer] number of subjects. Default `120`.
#' @param mu_g,mu_a,sigma_g,sigma_a,c_vec Model 2a truth for
#'   [sim_case_data_2a()]. Sensible defaults are provided.
#' @param noise_sd Residual SD on the log scale. Default `0.15`.
#' @param seed RNG seed for the simulation. Default `1`.
#' @param ... MCMC controls forwarded to [run_mod_2a()] (e.g. `nchain`,
#'   `niter`, `nmc`, `nburn`, `nadapt`).
#'
#' @returns A [data.frame] with columns `param`, `true_rho`, `cor_med`,
#'   `cor_lo`, `cor_hi`, and `verdict` ("recovered", "null ok", or "review").
#' @export
validate_recovery_2a <- function(
    n = 120,
    mu_g = c(0.0, 3.0, 2.3, -4.0, -1.0),
    mu_a = c(0.2, 3.1, 2.2, -3.8, -1.1),
    sigma_g = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
    sigma_a = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
    c_vec = c(0.054, 0.080, 0.0, 0.064, 0.0),
    noise_sd = 0.15,
    seed = 1,
    ...) {
  sim <- sim_case_data_2a(
    n = n, mu_g = mu_g, mu_a = mu_a,
    sigma_g = sigma_g, sigma_a = sigma_a, c_vec = c_vec,
    noise_sd = noise_sd, seed = seed
  )
  fit <- run_mod_2a(sim$data, ...)
  out <- fit$cross
  out$true_rho <- sim$truth$rho

  covers0 <- out$cor_lo <= 0 & out$cor_hi >= 0
  out$verdict <- ifelse(
    out$true_rho == 0,
    ifelse(covers0, "null ok", "review"),
    ifelse(!covers0, "recovered", "review")
  )

  out[, c("param", "true_rho", "cor_med", "cor_lo", "cor_hi", "verdict")]
}
