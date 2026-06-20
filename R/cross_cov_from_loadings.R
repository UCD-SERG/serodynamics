#' @title Convert factor loadings to cross-biomarker covariance
#' @description
#' In the Model 2a factor parameterization, the same-parameter cross-biomarker
#' covariance for biomarkers 1 and 2 is the product of their loadings:
#' \deqn{c_p = \lambda_{1,p}\,\lambda_{2,p}.}
#' This pure helper computes `c_p` for one MCMC draw (or any single set of
#' loadings). It contains no fitting logic and is trivial to unit-test.
#'
#' @param lambda_mat A `K x P` [matrix] of loadings, rows = biomarkers,
#'   columns = kinetic parameters. Only the first two rows are used (Model 2a
#'   pairs two biomarkers).
#'
#' @returns A length-`P` [numeric] [vector] of cross-biomarker covariances.
#' @export
cross_cov_from_loadings <- function(lambda_mat) {
  if (nrow(lambda_mat) < 2) {
    cli::cli_abort(
      "{.arg lambda_mat} needs at least 2 rows (biomarkers) for Model 2a."
    )
  }
  lambda_mat[1, ] * lambda_mat[2, ]
}
