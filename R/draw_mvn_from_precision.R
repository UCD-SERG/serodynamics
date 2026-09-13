#' @title Draw one multivariate normal vector given a precision matrix
#'
#' @description
#' Samples via the Cholesky factor of the precision matrix,
#' which avoids inverting it:
#' if `prec = t(R) %*% R`
#' then `mu + backsolve(R, z)` has covariance `solve(prec)`
#' for standard normal `z`.
#' Factorizing also checks that the matrix is positive definite,
#' so a malformed draw errors
#' instead of returning a silently wrong sample.
#'
#' @param mu A numeric mean vector.
#' @param prec A symmetric positive definite precision matrix.
#' @inheritParams draw_new_individual_params
#'
#' @returns A numeric vector the same length as `mu`.
#'
#' @keywords internal
#' @noRd
draw_mvn_from_precision <- function(mu,
                                    prec,
                                    call = rlang::caller_env()) {
  cholesky_factor <- tryCatch(
    chol(prec),
    error = function(condition) {
      cli::cli_abort(
        c(
          "The {.field prec.par} matrix for this draw
           is not positive definite.",
          "x" = conditionMessage(condition)
        ),
        call = call
      )
    }
  )
  
  standard_normal <- stats::rnorm(length(mu))
  
  sampled_values <- as.vector(mu + backsolve(cholesky_factor, standard_normal))
  
  return(sampled_values)
}
