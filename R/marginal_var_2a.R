#' @title Marginal within-biomarker variance under the factor model
#' @description
#' The Model 2a factor construction is
#' `par[i,k,p] = mu[k,p] + w[i,k,p] + lambda[k,p] * f[i,p]`, so the marginal
#' variance of parameter `p` for biomarker `k` is the within-biomarker variance
#' of `w` plus the squared loading:
#' \deqn{\mathrm{Var}(par_{k,p}) = (\mathrm{prec.par}_k^{-1})_{pp} +
#' \lambda_{k,p}^2.}
#' This pure helper returns that marginal variance vector for one biomarker, for
#' a single MCMC draw.
#'
#' @param prec_par_k A `P x P` precision [matrix] for biomarker `k` (the
#'   Wishart node `prec.par[k,,]`).
#' @param lambda_k A length-`P` [numeric] [vector] of loadings for biomarker
#'   `k`.
#'
#' @returns A length-`P` [numeric] [vector] of marginal variances.
#' @export
marginal_var_2a <- function(prec_par_k, lambda_k) {
  cov_w <- solve(prec_par_k)
  diag(cov_w) + lambda_k^2
}
