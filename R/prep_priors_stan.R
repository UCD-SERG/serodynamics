#' @title Prepare priors for Stan
#' @author Kwan Ho Lee
#' @description
#' Takes multiple [vector] inputs to allow for modifiable priors for Stan
#' models. Returns Stan-compatible prior specifications (matrix inversions
#' are handled in the Stan model itself).
#'
#' @inheritParams prep_priors
#' @param prec_hyp_param A [numeric] [vector] of 5 values corresponding to
#' hyperprior diagonal entries for the precision matrix (i.e. inverse variance)
#' representing prior covariance of uncertainty around `mu_hyp_param`.
#' If specified, must be 5 values long.
#' Stan defaults differ from JAGS (more weakly informative for HMC stability):
#'    - defaults: y0 = 1.0, y1 = 1/9 (~0.11), t1 = 1.0, alpha = 1/9, shape = 1.0
#'
#' @returns A "curve_params_priors_stan" object 
#' (a subclass of [list] with the inputs to `prep_priors_stan()` attached 
#' as [attributes] entry named `"used_priors"`), containing Stan-formatted
#' priors.
#' @export
#' @example inst/examples/examples-prep_priors_stan.R

prep_priors_stan <- function(
    max_antigens,
    mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),  # (y0, y1, t1, alpha, shape)
    prec_hyp_param = c(1.0, 1 / 9, 1.0, 1 / 9, 1.0),  # weakly-informative 
    # (SD~3); HMC-stable
    omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4.0, 1.0)) {
  
  # Validate input parameters
  validate_prior_params(
    mu_hyp_param = mu_hyp_param,
    prec_hyp_param = prec_hyp_param,
    omega_param = omega_param,
    wishdf_param = wishdf_param,
    prec_logy_hyp_param = prec_logy_hyp_param
  )
  
  # Initialize and fill prior arrays
  prior_arrays <- initialize_prior_arrays(
    max_antigens = max_antigens,
    mu_hyp_param = mu_hyp_param,
    prec_hyp_param = prec_hyp_param,
    omega_param = omega_param,
    wishdf_param = wishdf_param,
    prec_logy_hyp_param = prec_logy_hyp_param
  )
  
  # Return results as a list with Stan-specific naming
  prepped_priors <- list(
    "n_params" = prior_arrays$n_params,
    "mu_hyp" = prior_arrays$mu_hyp,
    "prec_hyp" = prior_arrays$prec_hyp,
    "omega" = prior_arrays$omega,
    "wishdf" = prior_arrays$wishdf,
    "prec_logy_hyp" = prior_arrays$prec_logy_hyp
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
