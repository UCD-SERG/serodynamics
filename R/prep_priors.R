#' @title Prepare priors
#' @description
#' Takes a [list] input to allow for modifiable priors. Priors can be specified
#' as an option in run_mod.
#' 
#' @param max_antigens A [numeric] [vector] specifying how many
#' antigen-isotypes will be modeled
#' @param mu_hyp_param A [numeric] [vector] of 5 values representing the mean of
#' the hyperprior distribution of the population mean of the random
#' person-specific seroresponse curve parameters.
#' If specified must be 5 values long representing the following parameters:
#'    - y0 = baseline antibody concentration (default = 1.0)
#'    - y1 = peak antibody concentration (default = 7.0)
#'    - t1 = time to peak (default = 1.0)
#'    - r = shape parameter (default = -4.0)
#'    - alpha = decay rate (default = -1.0)
#' @param prec_hyp_param A [numeric] [vector] of 5 values corresponding to
#' diagonal entries representing the precision matrix of the hyperprior
#' distribution of the person-specific seroresponse curve parameters.
#' If specified must be 5 values long:
#'    - defaults: y0 = 1.0, y1 = 0.00001, t1 = 1.0, r = 0.001, alpha = 1.0
#' @param omega_param A [numeric] [vector] of 5 values corresponding to diagonal
#' entries representing the precision matrix of Wishart hyper-priors for
#' person-specific random effects.
#' If specified must be 5 values long:
#'    - defaults: y0 = 1.0, y1 = 50.0, t1 = 1.0, r = 10.0, alpha = 1.0
#' @param wishdf_param A [numeric] [vector] of 1 value specifying Wishart
#' distribution degrees of freedom.
#' If specified, must be 1 value long.
#'    - default = 20.0
#' @param prec_logy_hyp_param A [numeric] [vector] of 2 values corresponding to
#' the hyper-parameters for the precision (inverse variance) of the biomarkers,
#' on log-scale. If specified, must be 2 values long.
#'    - defaults = 4.0, 1.0
#'
#' @returns A [list] with elements:
#' - "n_params": Corresponds to the 5 parameters being estimated.
#' - "mu.hyp": A [matrix] of hyperpriors with dimensions
#' number of antigens x 5 (number of parameters), representing the mean of the
#' hyperprior distribution: y0, y1, t1, r, and alpha).
#' - "prec.hyp": A three-dimensional [numeric] [array] with 5 [matrix], each
#' with dimensions number of antigens x 5 (# of parameters), representing
#' precision matrix of the hyperprior distribution
#' - "omega" : A three-dimensional [numeric] [array] with 5 [matrix],each
#' with dimensions number of antigens x 5 (# of parameters), representing the
#' precision matrix of Wishart hyper-priors
#' - "wishdf": A [vector] of 2 values specifying Wishart distribution degrees
#' of freedom.
#' - "prec.logy.hyp": A [matrix] of hyper-parameters for the precision
#' (inverse variance) of the biomarkers, on log-scale, measuring
#' number of antigens x 2.
#' @export
#' @examples
#' prep_priors(max_antigens = 2)
prep_priors <- function(max_antigens,
                        mu_hyp_param = NA,
                        prec_hyp_param = NA,
                        omega_param = NA,
                        wishdf_param = NA,
                        prec_logy_hyp_param = NA) {
  
  # Setting defaults for list
  defaults <- list(mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
                   prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
                   omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
                   wishdf_param = 20,
                   prec_logy_hyp_param = c(4.0, 1.0))

  # Checking to see if priors are specified and using them if so.
  if (!anyNA(mu_hyp_param)) { # were priors specified?
    # mu_hyp_param
    # Testing to see if 5 elements, will create error if not
    if (length(mu_hyp_param) == 5) {
      # Reassigning default to specified prior
      defaults[["mu_hyp_param"]] <- mu_hyp_param
    } else if (length(mu_hyp_param) != 5) {
      cli::cli_abort("Need to specify 5 priors for {.arg mu_hyp_param}")
    }
  }
  # prec_hyp_param
  if (!anyNA(prec_hyp_param)) { # were priors specified?
    # Testing to see if 5 elements, will create error if not
    if (length(prec_hyp_param) == 5) {
      # Reassigning default to specified prior
      defaults[["prec_hyp_param"]] <- prec_hyp_param
    } else if (length(mu_hyp_param) != 5) {
      cli::cli_abort("Need to specify 5 priors for {.arg prec_hyp_param}")
    }
  }
  # omega_hyp_param
  if (!anyNA(omega_param)) { # were priors specified?
    # Testing to see if 5 elements, will create error if not
    if (length(omega_param) == 5) {
      # Reassigning default to specified prior
      defaults[["omega_param"]] <- omega_param
    } else if (length(omega_param) != 5) {
      cli::cli_abort("Need to specify 5 priors for {.arg omega_param}")
    }
  }
  # wishdf_param
  if (!anyNA(wishdf_param)) { # were priors specified?
    # Testing to see if 5 elements, will create error if not
    if (length(wishdf_param) == 1) {
      # Reassigning default to specified prior
      defaults[["wishdf_param"]] <- wishdf_param
    } else if (length(wishdf_param) != 1) {
      cli::cli_abort("Need to specify 1 prior for {.arg wishdf_param}")
    }
  }
  # prec_logy_hyp_param
  if (!anyNA(prec_logy_hyp_param)) { # were priors specified?
    # Testing to see if 5 elements, will create error if not
    if (length(prec_logy_hyp_param) == 2) {
      # Reassigning default to specified prior
      defaults[["prec_logy_hyp_param"]] <- prec_logy_hyp_param
    } else if (length(wishdf_param) != 2) {
      cli::cli_abort("Need to specify 2 priors for {.arg prec_logy_hyp_param}")
    }
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
    mu_hyp[k.test, ] <- defaults[["mu_hyp_param"]]
    prec_hyp[k.test, , ] <- diag(defaults[["prec_hyp_param"]])
    omega[k.test, , ] <- diag(defaults[["omega_param"]])
    wishdf[k.test] <- defaults[["wishdf_param"]]
    prec_logy_hyp[k.test, ] <- defaults[["prec_logy_hyp_param"]] 
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
    structure(class = c("curve_params_priors", "list"))
  # Creating two objects in a list, one will be used in run_mod and the other
  # will be attached to run_mod output as an attribute. 
  to_return <- prepped_priors |> structure("used_priors" = defaults)

  return(to_return)
}
