#' Validate prior parameters
#'
#' @param mu_hyp_param Prior mean parameters
#' @param prec_hyp_param Prior precision parameters
#' @param omega_param Wishart hyperprior parameters
#' @param wishdf_param Wishart degrees of freedom
#' @param prec_logy_hyp_param Log-scale precision parameters
#'
#' @returns NULL (throws error if validation fails)
#' @keywords internal
#' @noRd
validate_prior_params <- function(mu_hyp_param,
                                  prec_hyp_param,
                                  omega_param,
                                  wishdf_param,
                                  prec_logy_hyp_param) {
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
  
  # For Stan: validate that precision/covariance parameters are positive and finite
  # (they are inverted in the Stan model, so invalid values cause runtime failures)
  if (any(!is.finite(prec_hyp_param)) || any(prec_hyp_param <= 0)) {
    cli::cli_abort("{.arg prec_hyp_param} must contain finite positive values (required for Stan model inversion)")
  }
  if (any(!is.finite(omega_param)) || any(omega_param <= 0)) {
    cli::cli_abort("{.arg omega_param} must contain finite positive values (required for Stan model inversion)")
  }
  if (any(!is.finite(prec_logy_hyp_param)) || any(prec_logy_hyp_param <= 0)) {
    cli::cli_abort("{.arg prec_logy_hyp_param} must contain finite positive values (required for Stan model inversion)")
  }
  
  # Wishart degrees of freedom must be >= number of parameters (5)
  if (!is.finite(wishdf_param) || wishdf_param < 5) {
    cli::cli_abort("{.arg wishdf_param} must be >= 5 (number of parameters)")
  }
  
  invisible(NULL)
}

#' Initialize and fill prior arrays
#'
#' @param max_antigens Number of antigen-isotype combinations
#' @param mu_hyp_param Prior mean parameters
#' @param prec_hyp_param Prior precision parameters
#' @param omega_param Wishart hyperprior parameters
#' @param wishdf_param Wishart degrees of freedom
#' @param prec_logy_hyp_param Log-scale precision parameters
#'
#' @returns A list with initialized prior arrays
#' @keywords internal
#' @noRd
initialize_prior_arrays <- function(max_antigens,
                                    mu_hyp_param,
                                    prec_hyp_param,
                                    omega_param,
                                    wishdf_param,
                                    prec_logy_hyp_param) {
  n_params <- 5
  mu_hyp <- array(NA, dim = c(max_antigens, n_params))
  prec_hyp <- array(NA, dim = c(max_antigens, n_params, n_params))
  omega <- array(NA, dim = c(max_antigens, n_params, n_params))
  wishdf <- rep(NA, max_antigens)
  prec_logy_hyp <- array(NA, dim = c(max_antigens, 2))
  
  for (k in 1:max_antigens) {
    mu_hyp[k, ] <- mu_hyp_param
    prec_hyp[k, , ] <- diag(prec_hyp_param)
    omega[k, , ] <- diag(omega_param)
    wishdf[k] <- wishdf_param
    prec_logy_hyp[k, ] <- prec_logy_hyp_param
  }
  
  list(
    n_params = n_params,
    mu_hyp = mu_hyp,
    prec_hyp = prec_hyp,
    omega = omega,
    wishdf = wishdf,
    prec_logy_hyp = prec_logy_hyp
  )
}
