#' Sample from posterior predictive distribution (Stan models)
#'
#' Generate posterior predictive samples for new observations using a fitted
#' Stan model. This function samples from the marginal posterior distribution
#' of model parameters to generate predictions for specified time points.
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
#' # Fit a Stan model
#' model_output <- run_mod_stan(
#'   data = my_data,
#'   file_mod = "model.stan",
#'   nchain = 4
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
  
  # Check if posterior samples are available
  if (!"post" %in% names(attributes(stan_model_output))) {
    cli::cli_abort(
      c(
        "Posterior samples not found in model output.",
        "i" = "Run {.fn run_mod_stan} with {.code with_post = TRUE}."
      )
    )
  }
  
  # Extract posterior samples
  post_samples <- attr(stan_model_output, "post")
  
  # Determine number of samples to use
  n_total_samples <- nrow(post_samples)
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
    post_samples <- post_samples[sample_idx, , drop = FALSE]
  }
  
  # Get number of antigens from model output
  n_antigens <- length(unique(stan_model_output$Iso_type))
  n_timepoints <- length(time_points)
  
  # Initialize array for predictions
  predictions <- array(
    NA_real_,
    dim = c(n_samples, n_timepoints, n_antigens),
    dimnames = list(
      sample = seq_len(n_samples),
      timepoint = paste0("t", time_points),
      antigen = unique(stan_model_output$Iso_type)
    )
  )
  
  # Extract parameter columns for each antigen
  # Parameters are: y0, y1, t1, alpha, shape (5 parameters per antigen)
  for (k in seq_len(n_antigens)) {
    # Column indices for this antigen's parameters
    param_cols <- paste0("par[", k, ",", 1:5, "]")
    
    # Check if columns exist
    if (!all(param_cols %in% colnames(post_samples))) {
      cli::cli_abort(
        c(
          "Parameter columns not found for antigen {k}.",
          "i" = "Expected columns: {.val {param_cols}}"
        )
      )
    }
    
    # Extract parameters for this antigen
    y0 <- post_samples[, param_cols[1]]
    y1 <- post_samples[, param_cols[2]]
    t1 <- post_samples[, param_cols[3]]
    alpha <- post_samples[, param_cols[4]]
    shape <- post_samples[, param_cols[5]]
    
    # Generate predictions for each time point
    for (t_idx in seq_along(time_points)) {
      t <- time_points[t_idx]
      
      # Antibody curve model (same as in Stan model)
      # Active phase (t <= t1): y0 + (y1 - y0) * (t/t1)^alpha
      # Recovery phase (t > t1): y1 * exp(-shape * (t - t1))
      
      y_pred <- ifelse(
        t <= t1,
        y0 + (y1 - y0) * (t / t1)^alpha,  # Active phase
        y1 * exp(-shape * (t - t1))        # Recovery phase
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
