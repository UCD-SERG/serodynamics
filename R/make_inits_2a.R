#' @title Initial-value factory for Model 2a chains
#' @description
#' Returns an inits function (of `chain`) for `runjags::run.jags()`. It reuses
#' [initsfunction()] for the per-chain RNG seed/name and adds modest starting
#' values for the new Model 2a nodes:
#'   - `lambda`: small positive starts (the first biomarker's loadings are
#'     constrained `> 0` in the model, so starts must be positive);
#'   - `mu.par`: started at the hyperprior means.
#' The within-biomarker random effects `w` and the factors `f` are left for
#' JAGS to initialise from their priors (`N(0, prec.par)` and `N(0,1)`), which
#' is robust.
#'
#' @param n_antigen_isos [integer] number of biomarkers.
#' @param n_params [integer] number of kinetic parameters (5).
#' @param mu_hyp A `n_antigen_isos x n_params` [matrix] of hyperprior means
#'   (the `mu.hyp` element of the priors).
#'
#' @returns A function `f(chain)` returning a list of initial values.
#' @export
make_inits_2a <- function(n_antigen_isos, n_params, mu_hyp) {
  force(n_antigen_isos); force(n_params); force(mu_hyp)
  function(chain) {
    base <- initsfunction(chain)
    lambda0 <- matrix(0.1, nrow = n_antigen_isos, ncol = n_params)
    c(base, list(lambda = lambda0, mu.par = mu_hyp))
  }
}
