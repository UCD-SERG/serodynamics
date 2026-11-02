# Validating inputs of prior_predict
validate_prior_predict_inputs <- function(mu_hyp,
                                          prec_hyp,
                                          omega,
                                          prec_logy_hyp,
                                          wishdf,
                                          n,
                                          n_params,
                                          noise,
                                          time) {
  
  # Checking input names to make sure all are present.
  # Validate simulation arguments
  if (!is.numeric(n) || length(n) != 1L ||
      !is.finite(n) || n < 1 || n != floor(n)) {
    cli::cli_abort("{.arg n} must be a positive integer.")
  }
  
  if (!is.logical(noise) || length(noise) != 1L ||
      is.na(noise)) {
    cli::cli_abort("{.arg noise} must be TRUE or FALSE.")
  }
  
  if (!is.numeric(time) || length(time) == 0L ||
      any(!is.finite(time))) {
    cli::cli_abort(
      "{.arg time} must contain finite numeric values."
    )
  }
  
  # Check the prepared values
  if (length(mu_hyp) != n_params ||
      length(diag(prec_hyp)) != n_params ||
      any(!is.finite(mu_hyp)) ||
      any(!is.finite(diag(prec_hyp))) ||
      any(diag(prec_hyp) <= 0)) {
    cli::cli_abort("Invalid prepared population-mean priors.")
  }
  
  if (!identical(dim(omega), c(n_params, n_params))) {
    cli::cli_abort(
      "The prepared Wishart matrix must be 5 by 5."
    )
  }
  
  if (length(wishdf) != 1L ||
      !is.finite(wishdf) ||
      wishdf < n_params) {
    cli::cli_abort(
      "{.arg wishdf_param} must be at least 5."
    )
  }
  
  if (length(prec_logy_hyp) != 2L ||
      any(!is.finite(prec_logy_hyp)) ||
      any(prec_logy_hyp <= 0)) {
    cli::cli_abort(
      "Observation-precision hyperparameters must be positive."
    )
  }
  
}
