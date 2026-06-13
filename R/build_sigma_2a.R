#' @title Assemble a Model 2a covariance matrix
#' @description
#' Builds the `2P x 2P` Model 2a (Chapter 1 + alpha) covariance matrix from
#' two within-biomarker blocks and a diagonal cross-biomarker block:
#' \deqn{\Sigma = \begin{pmatrix} \Sigma_G & C \\ C^\top & \Sigma_A
#' \end{pmatrix}, \quad C = \mathrm{diag}(c_1, \ldots, c_P).}
#' Setting `c_vec = 0` recovers the Chapter 1 block-diagonal covariance, so
#' Model 2a strictly nests Chapter 1.
#'
#' This is a small pure helper used by [sim_params_2a()] and the tests; it does
#' no model fitting.
#'
#' @param sigma_g A `P x P` within-biomarker covariance for biomarker 1 (e.g.
#'   IgG). Must be symmetric positive-definite.
#' @param sigma_a A `P x P` within-biomarker covariance for biomarker 2 (e.g.
#'   IgA). Must be symmetric positive-definite.
#' @param c_vec A length-`P` [numeric] [vector] of same-parameter
#'   cross-biomarker covariances (the diagonal of `C`).
#'
#' @returns A `2P x 2P` symmetric covariance [matrix]. Errors if the result is
#'   not positive-definite (i.e. the requested cross-covariances are too large).
#' @export
build_sigma_2a <- function(sigma_g, sigma_a, c_vec) {
  p <- nrow(sigma_g)
  if (ncol(sigma_g) != p || nrow(sigma_a) != p || ncol(sigma_a) != p) {
    stop("`sigma_g` and `sigma_a` must both be P x P with the same P.")
  }
  if (length(c_vec) != p) {
    stop("`c_vec` must have length P (one cross-covariance per parameter).")
  }

  cmat <- diag(c_vec, nrow = p)
  sigma <- rbind(
    cbind(sigma_g, cmat),
    cbind(t(cmat), sigma_a)
  )

  # Positive-definiteness check (cross-covariances must be admissible)
  eig <- min(eigen(sigma, symmetric = TRUE, only.values = TRUE)$values)
  if (eig <= 0) {
    stop(
      "Assembled Sigma is not positive-definite (smallest eigenvalue ",
      round(eig, 4), "); reduce the magnitude of `c_vec`."
    )
  }
  sigma
}
