#' @title Compute Posterior Predictions at Specified Timepoints
#' @description
#' Internal helper that extracts posterior predicted antibody values at 
#' specified timepoints using MCMC samples from the posterior distribution.
#' This function provides the shared prediction logic used by both 
#' [plot_predicted_curve()] and [compute_residual_metrics()].
#'
#' @param model An `sr_model` object (returned by [run_mod()]) containing 
#'   samples from the posterior distribution of the model parameters.
#' @param ids Character vector of participant IDs to predict for.
#' @param antigen_iso The antigen isotype to predict for (e.g., "HlyE_IgA").
#' @param times Numeric vector of timepoints (in days) at which to compute
#'   predictions.
#' 
#' @return A [dplyr::tbl_df] with columns:
#'   - `id`: participant ID
#'   - `t`: time in days
#'   - `sample_id`: MCMC sample identifier
#'   - `Chain`: MCMC chain number
#'   - `Iteration`: MCMC iteration number
#'   - `res`: predicted antibody value at time `t` for the given sample
#'   
#' @keywords internal
#' @noRd
predict_posterior_at_times <- function(model,
                                      ids,
                                      antigen_iso,
                                      times) {
  
  # Filter to the subject(s) & antigen of interest
  sr_model_sub <- model |>
    dplyr::filter(
      .data$Subject %in% ids,
      .data$Iso_type == antigen_iso
    )
  
  # Pivot to wide format: one row per iteration/chain
  param_medians_wide <- sr_model_sub |>
    dplyr::select(
      all_of(c("Chain",
               "Iteration",
               "Iso_type",
               "Parameter",
               "value",
               "Subject"))
    ) |>
    tidyr::pivot_wider(
      names_from  = c("Parameter"),
      values_from = c("value")
    ) |>
    dplyr::arrange(.data$Chain, .data$Iteration) |>
    dplyr::mutate(
      antigen_iso = factor(.data$Iso_type),
      id = as.factor(.data$Subject),
      r = .data$shape
    ) |>
    dplyr::select(-c("Iso_type", "Subject"))
  
  # Add sample_id if not present
  if (!"sample_id" %in% names(param_medians_wide)) {
    param_medians_wide <- param_medians_wide |>
      dplyr::mutate(sample_id = dplyr::row_number())
  }
  
  # Prepare time grid
  dt1 <- data.frame(t = times) |>
    dplyr::mutate(idx = dplyr::row_number()) |>
    tidyr::pivot_wider(names_from = "idx", 
                       values_from = "t", 
                       names_prefix = "time") |>
    dplyr::slice(
      rep(seq_len(dplyr::n()), each = nrow(param_medians_wide))
    )
  
  # Compute predictions using the antibody curve model
  predictions <- cbind(param_medians_wide, dt1) |>
    tidyr::pivot_longer(cols = dplyr::starts_with("time"), 
                        values_to = "t") |>
    dplyr::select(-c("name")) |>
    dplyr::mutate(res = ab(.data$t, 
                           .data$y0, 
                           .data$y1, 
                           .data$t1, 
                           .data$alpha, 
                           .data$shape))
  
  return(predictions)
}
