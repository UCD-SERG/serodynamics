#' @title Prepare priors
#'
#' @param max_antigens [integer]: how many antigen-isotypes will be modeled
#'
#' @returns a [list] with elements:
#' "n_params": how many parameters??
#' - "mu.hyp": ??
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
                        mu_hyp <- c(1.0, 7.0, 1.0, -4.0, -1.0),
                        prec_hyp <- c(1.0, 0.00001, 1.0, 0.001, 1.0),
                        omega <- c(1.0, 50.0, 1.0, 10.0, 1.0),
                        wishdf <- 20,
                        prec_logy_hyp <- c(4.0, 1.0)) {
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
    mu_hyp[k.test, ] <- mu_hyp
    prec_hyp[k.test, , ] <- diag(prec_hyp)
    omega[k.test, , ] <- diag(omega)
    wishdf[k.test] <- wishdf
    prec_logy_hyp[k.test, ] <- prec_logy_hyp 
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
