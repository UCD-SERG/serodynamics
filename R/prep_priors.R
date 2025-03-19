#' @title Prepare priors
#'
#' @param max_antigens [integer]: how many antigen-isotypes will be modeled
#'
#' @returns a [list] with elements:
#' "n_params": how many parameters??
#' - "mu.hyp": The antibody dynamic curve includes the following parameters:
#'    - y0 = baseline antibody concentration
#'    - y1 = peak antibody concentration
#'    - t1 = time to peak
#'    - r = shape parameter
#'    - alpha = decay rate
#' - "prec.hyp": ??
#' - "omega" : ??
#' - "wishdf": Wishart distribution degrees of freedom
#' - "prec.logy.hyp": array of hyper-parameters for the precision
#' (inverse variance) of the biomarkers, on log-scale
#' @export
#'
#' @examples
#' prep_priors(max_antigens = 2)
prep_priors <- function(max_antigens,
                        priors = list ()){
  #Setting defaults for list)
  defaults <- list(mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
                   prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
                   omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
                   wishdf_param = 20,
                   prec_logy_hyp_param = c(4.0, 1.0))
  if (sum(is.na(priors)) < 5) {
    ## Testing for mu_hyp_param
    if (length(priors$mu_hyp_param) == 5) {
      defaults$mu_hyp_param <- priors$mu_hyp_param
    } else if (length(priors$mu_hyp_param) != 5) {
      stop("Need to specify 5 priors for mu_hyp_param")
    }
    ## Testing for prec_hyp_param
    if (length(priors$prec_hyp_param) == 5) {
      defaults$prec_hyp_param <- priors$prec_hyp_param
    } else if (length(priors$prec_hyp_param) != 5) {
      stop("Need to specify 5 priors for prec_hyp_param")
    }
    ## Testing for omega_param
    if (length(priors$omega_param) == 5) {
      defaults$omega_param <- priors$omega_param
    } else if (length(priors$omega_param) != 5) {
      stop("Need to specify 5 priors for omega_param")
    }
    ## Testing for wishdf_param
    if (length(priors$mu_hyp_param) == 1) {
      defaults$mu_hyp_param <- priors$mu_hyp_param
    } else if (length(priors$mu_hyp_param) != 1) {
      stop("Need to specify 1 prior for omega_param")
    }
    ## Testing for prec_logy_hyp_param
    if (length(priors$prec_logy_hyp_param) == 2) {
      defaults$prec_logy_hyp_param <- priors$prec_logy_hyp_param
    } else if (length(priors$prec_logy_hyp_param) != 5) {
      stop("Need to specify 2 priors for prec_logy_hyp_param")
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
    mu_hyp[k.test, ] <- mu_hyp_param
    prec_hyp[k.test, , ] <- diag(prec_hyp_param)
    omega[k.test, , ] <- diag(omega_param)
    wishdf[k.test] <- wishdf_param
    prec_logy_hyp[k.test, ] <- prec_logy_hyp_param 
  }

  # test for change

  # Return results as a list

  to_return <- list(
    "n_params" = n_params,
    "mu.hyp" = mu_hyp,
    "prec.hyp" = prec_hyp,
    "omega" = omega,
    "wishdf" = wishdf,
    "prec.logy.hyp" = prec_logy_hyp
  ) |>
    structure(class = c("curve_params_priors", "list"))

  return(to_return)
}
