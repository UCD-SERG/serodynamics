#' @title Convert loadings + precisions to cross-biomarker correlation
#' @description
#' Combines [cross_cov_from_loadings()] and [marginal_var_2a()] to give the
#' same-parameter cross-biomarker correlation for a single MCMC draw:
#' \deqn{\rho_p = c_p / \sqrt{\mathrm{Var}(par_{1,p})\,\mathrm{Var}(par_{2,p})}.}
#'
#' @param lambda_mat A `K x P` loadings [matrix] (rows = biomarkers).
#' @param prec_par_1 A `P x P` precision [matrix] for biomarker 1.
#' @param prec_par_2 A `P x P` precision [matrix] for biomarker 2.
#'
#' @returns A length-`P` [numeric] [vector] of cross-biomarker correlations.
#' @export
cross_cor_from_draw_2a <- function(lambda_mat, prec_par_1, prec_par_2) {
  cp <- cross_cov_from_loadings(lambda_mat)
  v1 <- marginal_var_2a(prec_par_1, lambda_mat[1, ])
  v2 <- marginal_var_2a(prec_par_2, lambda_mat[2, ])
  cp / sqrt(v1 * v2)
}
