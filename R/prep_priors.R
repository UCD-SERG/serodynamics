#' @title Prepare priors
#' @description
#' Takes a [list] input to allow for modifiable priors. Priors can be specified
#' as an option in run_mod.
#' 
#' @param max_antigens [integer]: how many antigen-isotypes will be modeled
#' @param priors a [list] with optional elements:
#' - "mu_hyp_param": hyperpriors for estimate parameters. If specified must
#'    be 5 values long.
#'    - y0 = baseline antibody concentration (default = 1.0)
#'    - y1 = peak antibody concentration (default = 7.0)
#'    - t1 = time to peak (default = 1.0)
#'    - r = shape parameter (default = -4.0)
#'    - alpha = decay rate (default = -1.0)
#' - "prec_hyp_param": Precision corresponding to mu_hyp_param. If specified
#' must 5 values long.
#'    - defaults: y0 = 1.0, y1 = 0.00001, t1 = 1.0, r = 0.001, alpha = 1.0
#' - "omega_param": Diagonal entries of the scale matrix hyper-parameter for 
#' the Wishart hyper-prior on the precision matrix of the person-specific 
#' random effects. If specified, must 5 values long.
#'    - defaults: y0 = 1.0, y1 = 50.0, t1 = 1.0, r = 10.0, alpha = 1.0
#' - "wishdf_param": Wishart distribution degrees of freedom.
#'    - default = 20.0
#' - "prec_logy_hyp_param": array of hyper-parameters for the precision.
#'    (inverse variance) of the biomarkers, on log-scale
#'    - defaults = 4.0, 1.0
#'
#' @returns a [list] with elements:
#' "n_params": how many parameters??
#' - "mu.hyp": Hyperpriors for y0, y1, t1, r, and alpha.
#' - "prec.hyp": Precision corresponding to mu_hyp_param.
#' - "omega" : a three-dimensional [numeric] [array] containing the 
#' "scale matrix" hyper-parameters of the Wishart hyper-priors 
#' on the person-specific random effects, for each antigen-isotype.
#' The first dimension corresponds to the antigen isotypes and has length equal to `max_antigens`,
#' and the latter two dimensions correspond to the model parameters and each have length equal to `n_params`
#'    - defaults: y0 = 1.0, y1 = 50.0, t1 = 1.0, r = 10.0, alpha = 1.0
#' - "wishdf": Wishart distribution degrees of freedom (default = 20.0)
#' - "prec.logy.hyp": array of hyper-parameters for the precision
#'    - defaults = 4.0, 1.0
#' (inverse variance) of the biomarkers, on log-scale
#' @export
#' @examples
#' prep_priors(max_antigens = 2)
prep_priors <- function(max_antigens,
                        priors = NA) {
  # Setting defaults for list
  defaults <- list(mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
                   prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
                   omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
                   wishdf_param = 20,
                   prec_logy_hyp_param = c(4.0, 1.0))

  # Checking to see if priors are specified and using them if so.
  if (methods::hasArg(priors)) { # were priors specified?
    # mu_hyp_param
    if ((sum(names(priors) %in% "mu_hyp_param")) > 0) {
      # Testing to see if 5 elements, will create error if not
      if (length(priors[["mu_hyp_param"]]) == 5) {
        # Reassigning default to specified prior
        defaults[["mu_hyp_param"]] <- priors[["mu_hyp_param"]]
      } else if (length(priors[["mu_hyp_param"]]) != 5) {
        stop("Need to specify 5 priors for mu_hyp_param")
      }
    }
    # prec_hyp_param
    if ((sum(names(priors) %in% "prec_hyp_param")) > 0) {
      # Testing to see if 5 elements, will create error if not
      if (length(priors[["prec_hyp_param"]]) == 5) {
        # Reassigning default to specified prior
        defaults[["prec_hyp_param"]] <- priors[["prec_hyp_param"]]
      } else if (length(priors[["mu_hyp_param"]]) != 5) {
        stop("Need to specify 5 priors for prec_hyp_param")
      }
    }
    # omega_hyp_param
    if ((sum(names(priors) %in% "omega_param")) > 0) {
      # Testing to see if 5 elements, will create error if not
      if (length(priors[["omega_param"]]) == 5) {
        # Reassigning default to specified prior
        defaults[["omega_param"]] <- priors[["omega_param"]]
      } else if (length(priors[["omega_param"]]) != 5) {
        stop("Need to specify 5 priors for omega_param")
      }
    }
    # wishdf_param
    if ((sum(names(priors) %in% "wishdf_param")) > 0) {
      # Testing to see if 5 elements, will create error if not
      if (length(priors[["wishdf_param"]]) == 1) {
        # Reassigning default to specified prior
        defaults[["wishdf_param"]] <- priors[["wishdf_param"]]
      } else if (length(priors[["wishdf_param"]]) != 1) {
        stop("Need to specify 5 priors for wishdf_param")
      }
    }
    # prec_logy_hyp_param
    if ((sum(names(priors) %in% "prec_logy_hyp_param")) > 0) {
      # Testing to see if 5 elements, will create error if not
      if (length(priors[["prec_logy_hyp_param"]]) == 2) {
        # Reassigning default to specified prior
        defaults[["prec_logy_hyp_param"]] <- priors[["prec_logy_hyp_param"]]
      } else if (length(priors[["wishdf_param"]]) != 2) {
        stop("Need to specify 5 priors for prec_logy_hyp_param")
      }
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
