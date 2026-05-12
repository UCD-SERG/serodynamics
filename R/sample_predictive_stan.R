#' Sample from posterior predictive distribution (Stan models)
#'
#' Generate posterior predictive samples for new observations using a fitted
#' Stan model. This function samples from the population-level parameter
#' distribution and includes measurement error to generate true posterior
#' predictive samples (not just mean curve draws). Predictions are made on
#' the original antibody concentration scale.
#'
#' @param stan_model_output Output from [run_mod_stan()], an object of class
#'   `sr_model` containing the fitted Stan model
#' @param time_points Numeric vector of time points (in days) at which to
#'   generate predictions. Default is `c(5, 30, 90)`.
#' @param n_samples Number of posterior samples to draw. If `NULL` (default),
#'   uses all available posterior samples from the model.
#'
#' @returns A list of class `posterior_predictive_stan` containing:
#'   \item{samples}{Array of posterior predictive samples with dimensions
#'     `[n_samples, n_timepoints, n_antigens]`. These include measurement
#'     error and represent plausible new observations.}
#'   \item{time_points}{The time points used for prediction}
#'   \item{summary}{Summary statistics (mean, median, 95\% credible intervals)
#'     for each antigen at each time point}
#'
#' @details
#' This function generates true posterior predictive samples by:
#' \enumerate{
#'   \item Extracting population-level parameter draws (mu_par) from the
#'         fitted model
#'   \item Computing the mean antibody curve at each time point using [ab()]
#'   \item Adding measurement error sampled from Normal(0, sigma_logy) where
#'         sigma_logy = 1/sqrt(prec_logy)
#'   \item Transforming back to the original antibody concentration scale
#' }
#'
#' The resulting samples represent plausible new observations, not just the
#' mean curve. For stratified models, draws from all strata are combined.
#'
#' @importFrom stats median quantile rnorm
#' @export
#'
#' @examples
#' \dontrun{
#' # Fit a Stan model with posterior samples
#' model_output <- run_mod_stan(
#'   data = my_data,
#'   file_mod = "model.stan",
#'   nchain = 4,
#'   with_post = TRUE
#' )
#'
#' # Generate posterior predictive samples
#' predictions <- sample_predictive_stan(
#'   model_output,
#'   time_points = c(5, 30, 90)
#' )
#'
#' # Access summary statistics
#' print(predictions$summary)
#' }
sample_predictive_stan <- function(
    stan_model_output,
    time_points = c(5, 30, 90),
    n_samples = NULL) {
  
  # Validate input
  if (!inherits(stan_model_output, "sr_model")) {
    cli::cli_abort(
      c(
        "{.arg stan_model_output} must be output from {.fn run_mod_stan}.",
        "x" = "Received object of class {.cls {class(stan_model_output)}}."
      )
    )
  }
  
  # Check if posterior samples are available (stored as "stan.fit" attribute)
  if (!"stan.fit" %in% names(attributes(stan_model_output))) {
    cli::cli_abort(
      c(
        "Posterior samples not found in model output.",
        "i" = "Run {.fn run_mod_stan} with {.code with_post = TRUE}."
      )
    )
  }
  
  # Extract CmdStan fit object(s)
  stan_fit_list <- attr(stan_model_output, "stan.fit")
  
  # Get number of antigens and stratification levels
  n_antigens <- length(unique(stan_model_output$Iso_type))
  antigen_names <- unique(stan_model_output$Iso_type)
  n_timepoints <- length(time_points)
  
  # Initialize list to collect draws from all strata
  all_draws <- list()
  
  # Extract draws from each stratification level
  # We extract population-level parameters (mu_par, prec_logy)
  # which are consistent across strata and can be combined
  for (strat_name in names(stan_fit_list)) {
    stan_fit <- stan_fit_list[[strat_name]]
    
    # Extract population-level parameter draws (not subject-specific)
    # mu_par: population mean for each parameter and antigen
    # prec_logy: measurement error precision
    draws <- stan_fit$draws(
      variables = c("mu_par", "prec_logy"),
      format = "draws_matrix"
    )
    
    all_draws[[strat_name]] <- draws
  }
  
  # Combine draws from all strata (these have same dimensions)
  combined_draws <- do.call(rbind, all_draws)
  
  # Determine number of samples to use
  n_total_samples <- nrow(combined_draws)
  if (is.null(n_samples)) {
    n_samples <- n_total_samples
  } else if (n_samples > n_total_samples) {
    cli::cli_warn(
      c(
        "Requested {n_samples} samples but only {n_total_samples} available.",
        "i" = "Using all {n_total_samples} samples."
      )
    )
    n_samples <- n_total_samples
  }
  
  # Sample indices
  if (n_samples < n_total_samples) {
    sample_idx <- sample(seq_len(n_total_samples), n_samples, replace = FALSE)
    combined_draws <- combined_draws[sample_idx, , drop = FALSE]
  }
  
  # Initialize array for predictions
  predictions <- array(
    NA_real_,
    dim = c(n_samples, n_timepoints, n_antigens),
    dimnames = list(
      sample = seq_len(n_samples),
      timepoint = paste0("t", time_points),
      antigen = antigen_names
    )
  )
  
  # Generate predictions for each antigen
  for (k in seq_len(n_antigens)) {
    # Extract parameter columns for this antigen
    # CmdStan names: y0[subj,k], y1[subj,k], etc.
    # We need to find columns matching pattern for antigen k
    # Extract population-level parameters for this antigen
    # mu_par has dimensions [param, antigen] where param = 1:5
    # (y0, y1, t1, alpha, shape)
    y0_pop <- combined_draws[, paste0("mu_par[1,", k, "]")]
    y1_pop <- combined_draws[, paste0("mu_par[2,", k, "]")]
    t1_pop <- combined_draws[, paste0("mu_par[3,", k, "]")]
    alpha_pop <- combined_draws[, paste0("mu_par[4,", k, "]")]
    shape_pop <- combined_draws[, paste0("mu_par[5,", k, "]")]
    
    # Extract measurement error precision for this antigen
    prec_logy_k <- combined_draws[, paste0("prec_logy[", k, "]")]
    sigma_logy_k <- 1 / sqrt(prec_logy_k)  # Convert precision to SD
    
    # Generate posterior predictive samples for each time point
    for (t_idx in seq_along(time_points)) {
      t <- time_points[t_idx]
      
      # Compute mean log(antibody) using ab() function
      mu_logy <- ab(
        t = t,
        y0 = y0_pop,
        y1 = y1_pop,
        t1 = t1_pop,
        alpha = alpha_pop,
        shape = shape_pop
      )
      
      # Add measurement error to get posterior predictive samples
      logy_pred <- stats::rnorm(
        n = length(mu_logy),
        mean = mu_logy,
        sd = sigma_logy_k
      )
      
      # Transform back to original scale
      y_pred <- exp(logy_pred)
      
      predictions[, t_idx, k] <- y_pred
    }
  }
  
  # Compute summary statistics
  summary_list <- list()
  for (k in seq_len(n_antigens)) {
    antigen_name <- dimnames(predictions)$antigen[k]
    summary_list[[antigen_name]] <- data.frame(
      time_point = time_points,
      mean = apply(predictions[, , k], 2, mean),
      median = apply(predictions[, , k], 2, median),
      lower_95 = apply(predictions[, , k], 2, quantile, probs = 0.025),
      upper_95 = apply(predictions[, , k], 2, quantile, probs = 0.975),
      row.names = NULL
    )
  }
  
  # Return results
  result <- list(
    samples = predictions,
    time_points = time_points,
    summary = summary_list
  )
  
  class(result) <- c("posterior_predictive_stan", "list")
  return(result)
}
