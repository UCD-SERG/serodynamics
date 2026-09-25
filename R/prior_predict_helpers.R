# Validating inputs of prior_predict
validate_prior_predict_inputs <- function(x) {
  
  required_names <- c(
    "mu_hyp_param",
    "prec_hyp_param",
    "omega_param",
    "wishdf_param",
    "prec_logy_hyp_param",
    "n",
    "n_params",
    "seed"
  )
  
  missing_names <- setdiff(required_names, names(x))
  
  if (length(missing_names) > 0) {
    cli::cli_abort(c(
      "x" = "Input is missing required elements.",
      "i" = "Missing: {paste(missing_names, collapse = ', ')}"
    ))
  }
  
  n_params <- x$n_params
  
  ## Check required priors
  prior_names <- c(
    "mu_hyp_param",
    "prec_hyp_param",
    "omega_param",
    "wishdf_param",
    "prec_logy_hyp_param"
  )
  
  missing_priors <- prior_names[
    vapply(x[prior_names], is.null, logical(1))
  ]
  
  if (length(missing_priors) > 0) {
    cli::cli_abort(c(
      "x" = "All prior arguments must be supplied.",
      "i" = "Missing: {paste(missing_priors, collapse = ', ')}"
    ))
  }
  
  ## mu_hyp_param
  if (length(x$mu_hyp_param) != n_params) {
    cli::cli_abort(
      "{.arg mu_hyp_param} must have length {n_params}."
    )
  }
  
  ## prec_hyp_param
  if (length(x$prec_hyp_param) != n_params) {
    cli::cli_abort(
      "{.arg prec_hyp_param} must have length {n_params}."
    )
  }
  
  if (any(x$prec_hyp_param <= 0)) {
    cli::cli_abort(
      "All values of {.arg prec_hyp_param} must be greater than zero."
    )
  }
  
  ## wishdf_param
  if (
    length(x$wishdf_param) != 1 ||
    x$wishdf_param < n_params
  ) {
    cli::cli_abort(
      "{.arg wishdf_param} must be at least {n_params}."
    )
  }
  
  ## prec_logy_hyp_param
  if (
    length(x$prec_logy_hyp_param) != 2 ||
    any(x$prec_logy_hyp_param <= 0)
  ) {
    cli::cli_abort(
      "{.arg prec_logy_hyp_param} must contain two positive values."
    )
  }
  
  ## n
  if (
    !is.numeric(x$n) ||
    length(x$n) != 1 ||
    is.na(x$n) ||
    x$n < 1
  ) {
    cli::cli_abort(
      "{.arg n} must be a positive integer."
    )
  }
  
  x$n <- as.integer(x$n)
  
  ## omega_param
  if (
    is.atomic(x$omega_param) &&
    is.null(dim(x$omega_param)) &&
    length(x$omega_param) == n_params
  ) {
    
    x$omega <- diag(x$omega_param)
    
  } else if (
    is.matrix(x$omega_param) &&
    all(dim(x$omega_param) == c(n_params, n_params))
  ) {
    
    x$omega <- x$omega_param
    
  } else {
    
    cli::cli_abort(
      "{.arg omega_param} must be a length-{n_params} vector or a
       {n_params} x {n_params} matrix."
    )
  }
  
  ## Ensure omega is positive definite
  tryCatch(
    chol(x$omega),
    error = function(e) {
      cli::cli_abort(
        "{.arg omega_param} must define a positive-definite matrix."
      )
    }
  )
  
  x
}