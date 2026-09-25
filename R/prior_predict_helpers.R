# Validating inputs of prior_predict
validate_prior_predict_inputs <- function(mu_hyp_param = mu_hyp_param,
                                          prec_hyp_param = prec_hyp_param,
                                          omega_param = omega_param,
                                          wishdf_param = wishdf_param,
                                          prec_logy_hyp_param = 
                                            prec_logy_hyp_param,
                                          n = n,
                                          n_params = n_params,
                                          seed = seed) {
  
  # Checking input names to make sure all are present.
  priors <- list(
    mu_hyp_param = mu_hyp_param,
    prec_hyp_param = prec_hyp_param,
    omega_param = omega_param,
    wishdf_param = wishdf_param,
    prec_logy_hyp_param = prec_logy_hyp_param
  )
  
  missing_priors <- names(priors)[vapply(priors, is.null, logical(1))]
  
  if (length(missing_priors) > 0) {
    cli::cli_abort(c(
      "x" = "All prior arguments must be supplied.",
      "i" = "Missing: {paste(missing_priors, collapse = ', ')}"
    ))
  }
  
  if (length(mu_hyp_param) != n_params) {
    cli::cli_abort(
      "{.arg mu_hyp_param} must have length {n_params}."
    )
  }
  
  if (length(prec_hyp_param) != n_params) {
    cli::cli_abort(
      "{.arg prec_hyp_param} must have length {n_params}."
    )
  }
  
  if (any(prec_hyp_param <= 0)) {
    cli::cli_abort(
      "All values of {.arg prec_hyp_param} must be greater than zero."
    )
  }
  
  ## Ensure omega is positive definite
  if (length(omega_param) != n_params) {
    cli::cli_abort(
      "{.arg omega_param} must have length {n_params}."
    )
  }
  
  if (any(omega_param <= 0)) {
    cli::cli_abort(
      "All values of {.arg omega_param} must be greater than zero."
    )
  }
  
  if (length(prec_logy_hyp_param) != 2 ||
        any(prec_logy_hyp_param <= 0)) {
    cli::cli_abort(
      "{.arg prec_logy_hyp_param} must contain two positive values."
    )
  }
  
  if (!is.numeric(x$n) ||
    length(x$n) != 1 ||
    is.na(x$n) ||
    !is.finite(x$n) ||
    x$n <= 0 ||
    x$n != floor(x$n)) {
    cli::cli_abort(
      "{.arg n} must be a positive integer."
    )
  }
  priors
}
