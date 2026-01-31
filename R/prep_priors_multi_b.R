#' @title Priors for the Kronecker (multi-biomarker) model
#' @author Kwan Ho Lee
#' @description
#' `prep_priors_multi_b()` builds Wishart hyperparameters for the
#' within-biomarker precision matrix `T_P` and the across-biomarker precision
#' matrix `T_B` used in the Kronecker prior `T = T_B %x% T_P`.
#'
#' @param n_blocks Integer scalar (B): number of biomarkers.
#' @param omega_p_scale Numeric length-5 vector for the diagonal of Omega_P
#'   (parameter scale).
#' @param nu_p Numeric scalar: degrees of freedom for
#'   `T_P ~ Wishart(Omega_P, nu_p)`.
#' @param omega_b_scale Numeric length-`n_blocks` vector for the diagonal of
#'   Omega_B (biomarker scale).
#' @param nu_b Numeric scalar: degrees of freedom for
#'   `T_B ~ Wishart(Omega_B, nu_b)`.
#'
#' @return A list with elements `OmegaP`, `nuP`, `OmegaB`, `nuB`.
#' @export
#' @example inst/examples/examples-prep_priors_multi_b.R
prep_priors_multi_b <- function(
  n_blocks,
  omega_p_scale = rep(0.1, 5),
  nu_p = 6,
  omega_b_scale = rep(1.0, n_blocks),
  nu_b = n_blocks + 1
) {
  # validations (cli::cli_abort is linter-approved)
  if (!is.numeric(n_blocks) || length(n_blocks) != 1L || n_blocks < 1 ||
        !isTRUE(all.equal(n_blocks, as.integer(n_blocks)))) {
    cli::cli_abort("`n_blocks` must be a positive integer of length 1.")
  }
  if (!is.numeric(omega_p_scale) || length(omega_p_scale) != 5L) {
    cli::cli_abort("`omega_p_scale` must be a numeric vector of length 5.")
  }
  if (!is.numeric(omega_b_scale) || length(omega_b_scale) != n_blocks) {
    cli::cli_abort(
      "`omega_b_scale` must be a numeric vector of length `n_blocks`."
    )
  }
  if (!is.numeric(nu_p) || length(nu_p) != 1L) {
    cli::cli_abort("`nu_p` must be a numeric scalar.")
  }
  if (!is.numeric(nu_b) || length(nu_b) != 1L) {
    cli::cli_abort("`nu_b` must be a numeric scalar.")
  }
  
  list(
    OmegaP = diag(omega_p_scale, nrow = 5),
    nuP    = nu_p,
    OmegaB = diag(omega_b_scale, nrow = n_blocks),
    nuB    = nu_b
  )
}
