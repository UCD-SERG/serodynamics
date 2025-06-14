#' @title Prepare priors
#' @description
#' Takes multiple [vector] inputs to allow for modifiable priors. 
#' Priors can be specified as an option in run_mod.
#' 
#' @param max_antigens An [integer] specifying how many
#' antigen-isotypes (biomarkers) will be modeled.
#' @param mu_hyp_param A [numeric] [vector] of 5 values representing the prior
#' mean for the population level parameters
#' parameters (y0, y1, t1, r, alpha) for each biomarker.
#' If specified, must be 5 values long, representing the following parameters:
#'    - y0 = baseline antibody concentration (default = 1.0)
#'    - y1 = peak antibody concentration (default = 7.0)
#'    - t1 = time to peak (default = 1.0)
#'    - r = shape parameter (default = -4.0)
#'    - alpha = decay rate (default = -1.0)
#' @param prec_hyp_param A [numeric] [vector] of 5 values corresponding to
#' hyperprior diagonal entries for the precision matrix (i.e. inverse variance)
#' representing prior covariance of uncertainty around `mu_hyp_param`.
#' If specified, must be 5 values long:
#'    - defaults: y0 = 1.0, y1 = 0.00001, t1 = 1.0, r = 0.001, alpha = 1.0
#' @param omega_param A [numeric] [vector] of 5 values corresponding to the
#' diagonal entries representing the Wishart hyperprior
#' distributions of `prec_hyp_param`, describing how much we expect parameters
#' to vary between individuals.
#' If specified, must be 5 values long:
#'    - defaults: y0 = 1.0, y1 = 50.0, t1 = 1.0, r = 10.0, alpha = 1.0
#' @param wishdf_param An [integer] [vector] of 1 value specifying the degrees
#' of freedom for the Wishart hyperprior distribution of `prec_hyp_param`.
#' If specified, must be 1 value long.
#'    - default = 20.0
#'    - The value of `wishdf_param` controls how informative the Wishart prior
#'      is. Higher values lead to tighter priors on individual variation.
#'      Lower values (e.g., 5–10) make the prior more weakly informative,
#'      which can help improve convergence if the model is over-regularized.
#' @param prec_logy_hyp_param A [numeric] [vector] of 2 values corresponding to
#' hyperprior diagonal entries on the log-scale for the precision matrix
#' (i.e. inverse variance) representing prior beliefs of individual variation.
#' If specified, must be 2 values long:
#'    - defaults = 4.0, 1.0
#'
#' @returns A "curve_params_priors" object 
#' (a subclass of [list] with the inputs to `prep_priors()` attached 
#' as [attributes]  named `"used_priors"`).
#' - "n_params": Corresponds to the 5 parameters being estimated.
#' - "mu.hyp": A [matrix] of hyperpriors with dimensions
#' `max_antigens` x 5 (# of parameters), representing the mean of the
#' hyperprior distribution for each biomarker: y0, y1, t1, r, and alpha).
#' - "prec.hyp": A three-dimensional [numeric] [array] 
#' with dimensions `max_antigens` x 5 (# of parameters), 
#' containing the precision matrices of the hyperprior distributions of
#' `mu.hyp`, for each biomarker.
#' - "omega" : A three-dimensional [numeric] [array] with 5 [matrix],each
#' with dimensions `max_antigens` x 5 (# of parameters), representing the
#' precision matrix of Wishart hyper-priors for `prec.hyp`.
#' - "wishdf": A [vector] of 2 values specifying the degrees of freedom
#' for the Wishart distribution used in the subject-level precision prior.
#' - "prec.logy.hyp": A [matrix] of hyper-parameters for the precision
#' (inverse variance) of individual variation measuring
#' `max_antigens` x 2, on the log-scale.
#' - `used_priors` = inputs to `prep_priors()` attached as attributes.
#' @export
#' @example inst/examples/examples-prep_priors.R

prep_priors <- function(max_antigens,
                        mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
                        prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
                        omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
                        wishdf_param = 20,
                        prec_logy_hyp_param = c(4.0, 1.0)) {

  # Ensuring the length of specified priors is correct.
  # mu_hyp_param
  if (length(mu_hyp_param) != 5) {
    cli::cli_abort("Need to specify 5 priors for {.arg mu_hyp_param}")
  }
  # prec_hyp_param
  if (length(mu_hyp_param) != 5) {
    cli::cli_abort("Need to specify 5 priors for {.arg prec_hyp_param}")
  }
  # omega_hyp_param
  if (length(omega_param) != 5) {
    cli::cli_abort("Need to specify 5 priors for {.arg omega_param}")
  }
  # wishdf_param
  if (length(wishdf_param) != 1) {
    cli::cli_abort("Need to specify 1 prior for {.arg wishdf_param}")
  }
  # prec_logy_hyp_param
  if (length(prec_logy_hyp_param) != 2) {
    cli::cli_abort("Need to specify 2 priors for {.arg prec_logy_hyp_param}")
  }


  # Model parameters
  n_params <- 5 # Assuming 5 model parameters [ y0, y1, t1, alpha, shape]
  mu_hyp <- array(NA, dim = c(max_antigens, n_params))
  prec_hyp <- array(NA, dim = c(max_antigens, n_params, n_params))
  omega <- array(NA, dim = c(max_antigens, n_params, n_params))
  wishdf <- rep(NA, max_antigens)
  prec_logy_hyp <- array(NA, dim = c(max_antigens, 2))

  # Fill parameter arrays
  # the parameters are log(c(y0,  y1,    t1,  alpha, shape-1))
  for (k.test in 1:max_antigens) {
    mu_hyp[k.test, ] <- mu_hyp_param
    prec_hyp[k.test, , ] <- diag(prec_hyp_param)
    omega[k.test, , ] <- diag(omega_param)
    wishdf[k.test] <- wishdf_param
    prec_logy_hyp[k.test, ] <- prec_logy_hyp_param
  }

  # Return results as a list

  prepped_priors <- list(
    "n_params" = n_params,
    "mu.hyp" = mu_hyp,
    "prec.hyp" = prec_hyp,
    "omega" = omega,
    "wishdf" = wishdf,
    "prec.logy.hyp" = prec_logy_hyp
  ) |>
    structure(
      class = c("curve_params_priors", "list"),
      "used_priors" = as.list(environment())
    )
  # Creating two objects in a list, one will be used in run_mod and the other
  # will be attached to run_mod output as an attribute. 
  prepped_priors <- prepped_priors |> 
    structure("used_priors" = list(
                                   mu_hyp_param = mu_hyp_param,
                                   prec_hyp_param = prec_hyp_param,
                                   omega_param = omega_param,
                                   wishdf_param = wishdf_param,
                                   prec_logy_hyp_param = prec_logy_hyp_param))

  return(prepped_priors)
}
