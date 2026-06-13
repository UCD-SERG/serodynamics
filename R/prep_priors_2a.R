#' @title Prepare priors for Model 2a
#' @description
#' Thin wrapper that builds the full Model 2a prior list: it calls
#' [prep_priors()] for the Chapter 1 hyperpriors (`mu.hyp`, `prec.hyp`,
#' `omega`, `wishdf`, `prec.logy.hyp`, `n_params`) and then appends the
#' factor-loading prior via [add_factor_priors()].
#'
#' Because Model 2a keeps the Chapter 1 priors intact, all Chapter 1 prior
#' arguments are forwarded unchanged through `...`.
#'
#' @param max_antigens An [integer]: number of biomarkers (must be >= 2 for
#'   Model 2a, which couples biomarkers).
#' @param prec_lambda Prior precision of the factor loadings (see
#'   [add_factor_priors()]). Default `0.25`.
#' @param ... Additional Chapter 1 prior arguments forwarded to [prep_priors()]
#'   (e.g. `mu_hyp_param`, `omega_param`, `wishdf_param`).
#'
#' @returns A prior [list] suitable for `model_2a.jags`.
#' @export
prep_priors_2a <- function(max_antigens, prec_lambda = 0.25, ...) {
  if (max_antigens < 2) {
    stop("Model 2a needs at least 2 biomarkers; `max_antigens` was ",
         max_antigens, ".")
  }
  prep_priors(max_antigens = max_antigens, ...) |>
    add_factor_priors(prec_lambda = prec_lambda)
}
