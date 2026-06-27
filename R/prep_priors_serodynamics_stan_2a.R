#' @title Prepare priors for the Chapter 2 Stan models
#' @author Kwan Ho Lee
#' @description
#' Builds the per-antigen prior inputs (`mu_hyp`, `prec_hyp`, `omega`, `wishdf`,
#' `prec_logy_hyp`) consumed by `model_2a.stan` and `model_2a_indep.stan`.
#'
#' These are the **same** per-antigen prior inputs as the Chapter 1 Stan model
#' (`prep_priors_stan()`), reproduced here so the Chapter 2 branch does not
#' depend on the (unmerged) Chapter 1 Stan PR. Keeping the inputs identical also
#' makes the Model 2a vs. Chapter 1 comparison fair: the marginal scale prior of
#' each parameter, and the within-antigen correlation prior, match Chapter 1.
#' `model_2a.stan` combines these per-antigen inputs into a single joint
#' covariance prior (see that file's `transformed data` block); `model_2a_indep`
#' uses them block-diagonally exactly as Chapter 1 does.
#'
#' @param max_antigens number of antigen-isotype combinations.
#' @param mu_hyp_param length-5 population-mean prior means
#'   `(y0, y1, t1, alpha, shape)` on the log scale.
#' @param prec_hyp_param length-5 prior precisions (diagonal) for the population
#'   mean (weakly informative, SD ~ 3, for HMC stability).
#' @param omega_param length-5 Wishart scale diagonal.
#' @param wishdf_param Wishart degrees of freedom (scalar).
#' @param prec_logy_hyp_param length-2 gamma(shape, rate) for measurement
#'   precision.
#'
#' @returns a named [list] with `n_params`, `mu_hyp`, `prec_hyp`, `omega`,
#'   `wishdf`, `prec_logy_hyp`, sized for `max_antigens`.
#' @export
prep_priors_serodynamics_stan_2a <- function(
    max_antigens,
    mu_hyp_param        = c(1.0, 7.0, 1.0, -4.0, -1.0),   # (y0, y1, t1, alpha, shape)
    prec_hyp_param      = c(1.0, 1 / 9, 1.0, 1 / 9, 1.0), # weakly-informative (SD ~ 3)
    omega_param         = c(1.0, 50.0, 1.0, 10.0, 1.0),
    wishdf_param        = 20,
    prec_logy_hyp_param = c(4.0, 1.0)) {

  .validate_prior_params_2a(
    mu_hyp_param, prec_hyp_param, omega_param, wishdf_param, prec_logy_hyp_param)

  if (!is.numeric(max_antigens) || length(max_antigens) != 1 ||
        max_antigens < 1 || max_antigens != as.integer(max_antigens)) {
    stop("`max_antigens` must be a positive integer, not ", max_antigens, ".")
  }

  n_params <- 5L
  mu_hyp        <- array(NA_real_, dim = c(max_antigens, n_params))
  prec_hyp      <- array(NA_real_, dim = c(max_antigens, n_params, n_params))
  omega         <- array(NA_real_, dim = c(max_antigens, n_params, n_params))
  wishdf        <- rep(NA_real_, max_antigens)
  prec_logy_hyp <- array(NA_real_, dim = c(max_antigens, 2))

  for (k in seq_len(max_antigens)) {
    mu_hyp[k, ]        <- mu_hyp_param
    prec_hyp[k, , ]    <- diag(prec_hyp_param)
    omega[k, , ]       <- diag(omega_param)
    wishdf[k]          <- wishdf_param
    prec_logy_hyp[k, ] <- prec_logy_hyp_param
  }

  list(
    n_params      = n_params,
    mu_hyp        = mu_hyp,
    prec_hyp      = prec_hyp,
    omega         = omega,
    wishdf        = wishdf,
    prec_logy_hyp = prec_logy_hyp
  )
}

# Internal validator (kept private to the Chapter 2 files to avoid depending on
# the Chapter 1 PR's prep_priors_helpers.R).
.validate_prior_params_2a <- function(mu_hyp_param,
                                      prec_hyp_param,
                                      omega_param,
                                      wishdf_param,
                                      prec_logy_hyp_param) {
  if (length(mu_hyp_param) != 5) stop("`mu_hyp_param` must have length 5.")
  if (length(prec_hyp_param) != 5) stop("`prec_hyp_param` must have length 5.")
  if (length(omega_param) != 5) stop("`omega_param` must have length 5.")
  if (length(wishdf_param) != 1) stop("`wishdf_param` must have length 1.")
  if (length(prec_logy_hyp_param) != 2) stop("`prec_logy_hyp_param` must have length 2.")
  if (any(!is.finite(prec_hyp_param)) || any(prec_hyp_param <= 0)) {
    stop("`prec_hyp_param` must be finite and positive.")
  }
  if (any(!is.finite(omega_param)) || any(omega_param <= 0)) {
    stop("`omega_param` must be finite and positive.")
  }
  if (any(!is.finite(prec_logy_hyp_param)) || any(prec_logy_hyp_param <= 0)) {
    stop("`prec_logy_hyp_param` must be finite and positive.")
  }
  if (!is.finite(wishdf_param) || wishdf_param < 5) {
    stop("`wishdf_param` must be >= 5 (number of curve parameters).")
  }
  invisible(NULL)
}
