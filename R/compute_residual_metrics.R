#' @title Compute Residual-Based Metrics for Posterior Predictions
#' @description
#' Computes residuals between observed antibody measurements and posterior 
#' predicted values at observed timepoints. Returns pointwise residuals and/or 
#' summary metrics (MAE, RMSE, SSE) at multiple aggregation levels.
#' 
#' This function provides quantitative posterior predictive diagnostics to 
#' complement visual assessments from [plot_predicted_curve()]. It evaluates 
#' how well the model predictions match observed data at the individual level.
#'
#' @param model An `sr_model` object (returned by [run_mod()]) containing 
#'   samples from the posterior distribution of the model parameters.
#' @param dataset A [dplyr::tbl_df] with observed antibody response data.
#'   Must contain:
#'   - `id`: participant ID
#'   - `timeindays` (or the time variable specified in the dataset attributes)
#'   - `value` (or the value variable specified in the dataset attributes)
#'   - `antigen_iso`: antigen-isotype combination
#' @param ids Character vector of participant IDs to compute residuals for.
#' @param antigen_iso The antigen isotype (e.g., "HlyE_IgA" or "HlyE_IgG").
#' @param scale Character string specifying the scale for residual computation.
#'   Options:
#'   - `"original"`: Compute residuals on the original measurement scale 
#'     (default).
#'   - `"log"`: Compute residuals on the log scale, i.e., 
#'     `log(obs) - log(pred_med)`. Non-positive values are removed with a 
#'     warning.
#' @param summary_level Character string specifying the aggregation level for 
#'   summary metrics. Options:
#'   - `"pointwise"`: Return one row per observation with individual residuals 
#'     (no summary).
#'   - `"id_antigen"`: Summary metrics per `id × antigen_iso` combination 
#'     (default).
#'   - `"antigen"`: Summary metrics per `antigen_iso` (aggregated across IDs).
#'   - `"overall"`: Single overall summary across all IDs and antigens.
#'
#' @return A [dplyr::tbl_df] containing:
#' 
#'   If `summary_level = "pointwise"`:
#'   - `id`: participant ID
#'   - `antigen_iso`: antigen-isotype combination
#'   - `t`: time in days
#'   - `obs`: observed value
#'   - `pred_med`: posterior median prediction
#'   - `pred_lower`: 2.5% quantile of posterior predictions
#'   - `pred_upper`: 97.5% quantile of posterior predictions
#'   - `residual`: raw residual (`obs - pred_med`)
#'   - `abs_residual`: absolute residual (`abs(obs - pred_med)`)
#'   - `sq_residual`: squared residual (`(obs - pred_med)^2`)
#'   
#'   If `summary_level` is `"id_antigen"`, `"antigen"`, or `"overall"`:
#'   - `id`: participant ID (if applicable to summary level)
#'   - `antigen_iso`: antigen-isotype combination (if applicable)
#'   - `MAE`: mean absolute error
#'   - `RMSE`: root mean squared error
#'   - `SSE`: sum of squared errors
#'   - `n_obs`: number of observations used in calculation
#'
#' @export
#'
#' @example inst/examples/examples-compute_residual_metrics.R
compute_residual_metrics <- function(model,
                                      dataset,
                                      ids,
                                      antigen_iso,
                                      scale = c("original", "log"),
                                      summary_level = c("id_antigen",
                                                        "pointwise",
                                                        "antigen",
                                                        "overall")) {
  
  # Validate arguments
  scale <- match.arg(scale)
  summary_level <- match.arg(summary_level)
  
  # Extract variable names from dataset attributes
  time_var <- dataset |> get_timeindays_var()
  value_var <- dataset |> serocalculator::get_values_var()
  
  # Filter observed data to the requested IDs and antigen
  observed_data <- dataset |>
    dplyr::rename(
      t = {{ time_var }},
      obs = {{ value_var }}
    ) |>
    dplyr::select(all_of(c("id", "t", "obs", "antigen_iso"))) |>
    dplyr::mutate(id = as.character(.data$id)) |>
    dplyr::filter(
      .data$id %in% .env$ids,
      .data$antigen_iso == .env$antigen_iso
    )
  
  # Check that we have observed data
  if (nrow(observed_data) == 0) {
    cli::cli_abort(c(
      "No observed data found for the specified IDs and antigen_iso.",
      "i" = "IDs: {.val {ids}}",
      "i" = "antigen_iso: {.val {antigen_iso}}"
    ))
  }
  
  # Extract unique observed timepoints
  obs_times <- sort(unique(observed_data$t))
  
  # Get posterior predictions at observed timepoints
  predictions_all <- predict_posterior_at_times(
    model = model,
    ids = ids,
    antigen_iso = antigen_iso,
    times = obs_times
  )
  
  # Summarize predictions: compute median and quantiles
  pred_summary <- predictions_all |>
    dplyr::summarise(
      .by = all_of(c("id", "t")),
      pred_med = stats::median(.data$res, na.rm = TRUE),
      pred_lower = stats::quantile(.data$res, probs = 0.025, na.rm = TRUE),
      pred_upper = stats::quantile(.data$res, probs = 0.975, na.rm = TRUE)
    ) |>
    dplyr::mutate(id = as.character(.data$id))
  
  # Join observed data with predictions
  residual_data <- observed_data |>
    dplyr::inner_join(pred_summary, by = c("id", "t"))
  
  # Handle scale transformation
  if (scale == "log") {
    # Check for non-positive values
    n_nonpos_obs <- sum(residual_data$obs <= 0)
    n_nonpos_pred <- sum(residual_data$pred_med <= 0)
    
    if (n_nonpos_obs > 0 || n_nonpos_pred > 0) {
      cli::cli_warn(c(
        paste0("Removing ", n_nonpos_obs + n_nonpos_pred, 
               " observation(s) with non-positive values for ",
               "log-scale residuals."),
        "i" = "Non-positive observed: {n_nonpos_obs}",
        "i" = "Non-positive predicted: {n_nonpos_pred}"
      ))
      
      residual_data <- residual_data |>
        dplyr::filter(.data$obs > 0, .data$pred_med > 0)
    }
    
    # Compute log-scale residuals
    residual_data <- residual_data |>
      dplyr::mutate(
        obs_log = log(.data$obs),
        pred_med_log = log(.data$pred_med),
        residual = .data$obs_log - .data$pred_med_log,
        abs_residual = abs(.data$residual),
        sq_residual = .data$residual^2
      ) |>
      dplyr::select(-c("obs_log", "pred_med_log"))
  } else {
    # Original scale residuals
    residual_data <- residual_data |>
      dplyr::mutate(
        residual = .data$obs - .data$pred_med,
        abs_residual = abs(.data$residual),
        sq_residual = .data$residual^2
      )
  }
  
  # Return pointwise residuals if requested
  if (summary_level == "pointwise") {
    return(residual_data |>
      dplyr::select(all_of(c(
        "id", "antigen_iso", "t", "obs", "pred_med",
        "pred_lower", "pred_upper",
        "residual", "abs_residual", "sq_residual"
      ))))
  }
  
  # Compute summary metrics based on requested level
  if (summary_level == "id_antigen") {
    summary_data <- residual_data |>
      dplyr::summarise(
        .by = all_of(c("id", "antigen_iso")),
        MAE = mean(.data$abs_residual, na.rm = TRUE),
        RMSE = sqrt(mean(.data$sq_residual, na.rm = TRUE)),
        SSE = sum(.data$sq_residual, na.rm = TRUE),
        n_obs = dplyr::n()
      )
  } else if (summary_level == "antigen") {
    summary_data <- residual_data |>
      dplyr::summarise(
        .by = "antigen_iso",
        MAE = mean(.data$abs_residual, na.rm = TRUE),
        RMSE = sqrt(mean(.data$sq_residual, na.rm = TRUE)),
        SSE = sum(.data$sq_residual, na.rm = TRUE),
        n_obs = dplyr::n()
      )
  } else if (summary_level == "overall") {
    summary_data <- residual_data |>
      dplyr::summarise(
        MAE = mean(.data$abs_residual, na.rm = TRUE),
        RMSE = sqrt(mean(.data$sq_residual, na.rm = TRUE)),
        SSE = sum(.data$sq_residual, na.rm = TRUE),
        n_obs = dplyr::n()
      )
  }
  
  return(summary_data)
}
