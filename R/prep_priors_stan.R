#' @title Prepare priors for Stan
#' @description
#' Takes multiple [vector] inputs to allow for modifiable priors for Stan
#' models. Converts JAGS precision-based priors to Stan covariance-based
#' priors.
#' 
#' @inheritParams prep_priors
#'
#' @returns A "curve_params_priors_stan" object 
#' (a subclass of [list] with the inputs to `prep_priors_stan()` attached 
#' as [attributes] entry named `"used_priors"`), containing Stan-formatted
#' priors.
#' @export
#' @example inst/examples/examples-prep_priors_stan.R

prep_priors_stan <- function(
    max_antigens,
    mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
    prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
    omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4.0, 1.0)) {
  
  # Input validation (same as prep_priors)
  if (length(mu_hyp_param) != 5) {
    cli::cli_abort("Need to specify 5 priors for {.arg mu_hyp_param}")
  }
  if (length(prec_hyp_param) != 5) {
    cli::cli_abort("Need to specify 5 priors for {.arg prec_hyp_param}")
  }
  if (length(omega_param) != 5) {
    cli::cli_abort("Need to specify 5 priors for {.arg omega_param}")
  }
  if (length(wishdf_param) != 1) {
    cli::cli_abort("Need to specify 1 prior for {.arg wishdf_param}")
  }
  if (length(prec_logy_hyp_param) != 2) {
    cli::cli_abort("Need to specify 2 priors for {.arg prec_logy_hyp_param}")
  }
  
  # Model parameters
  n_params <- 5
  mu_hyp <- array(NA, dim = c(max_antigens, n_params))
  prec_hyp <- array(NA, dim = c(max_antigens, n_params, n_params))
  omega <- array(NA, dim = c(max_antigens, n_params, n_params))
  wishdf <- rep(NA, max_antigens)
  prec_logy_hyp <- array(NA, dim = c(max_antigens, 2))
  
  # Fill parameter arrays (same structure as JAGS)
  for (k in 1:max_antigens) {
    mu_hyp[k, ] <- mu_hyp_param
    prec_hyp[k, , ] <- diag(prec_hyp_param)
    omega[k, , ] <- diag(omega_param)
    wishdf[k] <- wishdf_param
    prec_logy_hyp[k, ] <- prec_logy_hyp_param
  }
  
  # Return results as a list (Stan model will handle conversion)
  prepped_priors <- list(
    "n_params" = n_params,
    "mu_hyp" = mu_hyp,
    "prec_hyp" = prec_hyp,
    "omega" = omega,
    "wishdf" = wishdf,
    "prec_logy_hyp" = prec_logy_hyp
  ) |>
    structure(class = c("curve_params_priors_stan", "list"))
  
  # Add used priors as attributes
  prepped_priors <- prepped_priors |> 
    structure("used_priors" = list(
      mu_hyp_param = mu_hyp_param,
      prec_hyp_param = prec_hyp_param,
      omega_param = omega_param,
      wishdf_param = wishdf_param,
      prec_logy_hyp_param = prec_logy_hyp_param
    ))
  
  return(prepped_priors)
}
