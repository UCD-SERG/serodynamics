#' @title Build Kronecker priors specification
#' @author Kwan Ho Lee
#' @description
#'  `build_kron_priors()` combines base priors with Kronecker-specific
#'  hyperparameters for the correlated model. It cleans the base priors,
#'  adds the Kronecker priors, and includes the scalar `n_blocks`.
#'
#' @param base_priors A [base::list()] of priors from [prep_priors()].
#' @param n_blocks Integer scalar: number of biomarkers.
#'
#' @return A [base::list()] with cleaned base priors, Kronecker priors
#'   (OmegaP, nuP, OmegaB, nuB), and n_blocks.
#'
#' @seealso [prep_priors()], [clean_priors()], [prep_priors_multi_b()]
#' @keywords internal
build_kron_priors <- function(base_priors, n_blocks) {
  # Clean legacy fields from base priors
  base_priors <- clean_priors(base_priors)
  
  # Add Kronecker hyperpriors
  kron_priors <- prep_priors_multi_b(n_blocks = n_blocks)
  
  # Add scalar n_blocks
  B_scalar <- list(n_blocks = n_blocks)
  
  # Combine all pieces
  c(base_priors, kron_priors, B_scalar)
}
