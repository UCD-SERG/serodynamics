#' Sample from posterior predictive distribution (Stan models)
#'
#' Generate posterior predictive samples for new observations using a fitted
#' Stan model. This function samples from the marginal posterior distribution
#' of model parameters to generate predictions for specified time points using
#' the antibody dynamic curve model.
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
#'     `[n_samples, n_timepoints, n_antigens]`}
#'   \item{time_points}{The time points used for prediction}
#'   \item{summary}{Summary statistics (mean, median, 95\% credible intervals)
#'     for each antigen at each time point}
#'
#' @importFrom stats median quantile
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
  for (strat_name in names(stan_fit_list)) {
    stan_fit <- stan_fit_list[[strat_name]]
    
    # Extract parameter draws from CmdStan fit
    # Parameters: y0, y1, t1, alpha, shape (5 parameters per antigen)
    draws <- stan_fit$draws(
      variables = c("y0", "y1", "t1", "alpha", "shape"),
      format = "draws_matrix"
    )
    
    all_draws[[strat_name]] <- draws
  }
  
  # Combine draws from all strata
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
    y0_cols <- grep(
      paste0("y0\\[\\d+,", k, "\\]"),
      colnames(combined_draws),
      value = TRUE
    )
    y1_cols <- grep(
      paste0("y1\\[\\d+,", k, "\\]"),
      colnames(combined_draws),
      value = TRUE
    )
    t1_cols <- grep(
      paste0("t1\\[\\d+,", k, "\\]"),
      colnames(combined_draws),
      value = TRUE
    )
    alpha_cols <- grep(
      paste0("alpha\\[\\d+,", k, "\\]"),
      colnames(combined_draws),
      value = TRUE
    )
    shape_cols <- grep(
      paste0("shape\\[\\d+,", k, "\\]"),
      colnames(combined_draws),
      value = TRUE
    )
    
    # Average across subjects for population-level predictions
    y0_mean <- rowMeans(combined_draws[, y0_cols, drop = FALSE])
    y1_mean <- rowMeans(combined_draws[, y1_cols, drop = FALSE])
    t1_mean <- rowMeans(combined_draws[, t1_cols, drop = FALSE])
    alpha_mean <- rowMeans(combined_draws[, alpha_cols, drop = FALSE])
    shape_mean <- rowMeans(combined_draws[, shape_cols, drop = FALSE])
    
    # Generate predictions for each time point using ab() function
    for (t_idx in seq_along(time_points)) {
      t <- time_points[t_idx]
      
      # Use the ab() function for consistency with the model
      y_pred <- ab(
        t = t,
        y0 = y0_mean,
        y1 = y1_mean,
        t1 = t1_mean,
        alpha = alpha_mean,
        shape = shape_mean
      )
      
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
