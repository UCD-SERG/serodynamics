#' @title Calculates fitted and residual values for modeled outputs
#' @description
#'  `calc_fit_mod()` takes antibody kinetic parameter estimates and calculates
#'  fitted and residual values. Fitted values correspond to the estimated assay
#'  value (ex. ELISA units etc.) at time since infection (TSI). Residual values
#'  are calculated as the difference between fitted and observed values.
#' @param modeled_dat A [data.frame] of modeled antibody kinetic parameter
#' values.
#' @param original_data A [data.frame] of the original input dataset.
#' @param strat A [character] string specifying the stratification variable
#' name, or [NA] if no stratification is used.
#' @param min_value [numeric]; minimum value substituted in before taking
#' `log10()` of `fitted`/observed values, to avoid `-Inf` from `log10(0)`
#' when computing `log_residual*`.
#' @param decay_type A [character] string specifying the decay function
#'   (`"power"` or `"exponential"`). Passed through to `ab()`. Default is
#'   `"power"`.
#' @returns A [data.frame] attached as an [attributes] with the following
#' values:
#'   - Subject = ID number specifying an individual
#'   - Iso_type = The modeled antigen_isotype
#'   - Stratification = The variable used to stratify the model
#'   (`"None"` when no stratification is used)
#'   - t = Time since infection
#'   - fitted = The median (across posterior draws) fitted value for a given
#'   `t`
#'   - residual = The median (across posterior draws) residual, calculated as
#'   the difference between observed and fitted values for a given `t`
#'   - residual_low, residual_high = The 2.5% and 97.5% quantiles (across
#'   posterior draws) of the residual, giving a precision interval around
#'   `residual`
#'   - log_residual, log_residual_low, log_residual_high = As `residual`,
#'   `residual_low`, and `residual_high`, but computed on the log10 scale
#'   (i.e. `log10(observed) - log10(fitted)`, with values floored at
#'   `min_value` beforehand)
#'
#' @keywords internal
calc_fit_mod <- function(modeled_dat,
                         original_data,
                         strat = NA,
                         min_value = 0.01,
                         decay_type = "power") {
  
  if (!is.numeric(min_value) || length(min_value) != 1 ||
        is.na(min_value) || !is.finite(min_value) || min_value <= 0) {
    cli::cli_abort("{.arg min_value} must be a single positive number.")
  }
  
  # Creating a stratification in original data if not specified
  if (is.na(strat)) {
    original_data <- original_data |> mutate(Stratification = "None")
    strat_col <- c("Stratification" = "Stratification")
  } else {
    strat_col <- c("Stratification" = strat)
  }
  
  
  # Preparing original data for calculating fitted and residuals
  original_data <- original_data |>
    use_att_names() |>
    dplyr::mutate(.obs_row = dplyr::row_number()) |>
    dplyr::select(
                  dplyr::any_of(c(".obs_row", "Subject", "Iso_type", "t", 
                                  "result", strat_col)))

  # Wide-format posterior draws: one row per iteration/chain/subject/iso.
  draws_wide <- modeled_dat |>
    dplyr::select(
                  dplyr::all_of(c("Iteration", "Chain", "Subject", "Iso_type", 
                                  "Stratification", "Parameter", "value"))) |>
    tidyr::pivot_wider(names_from = "Parameter", values_from = "value")
  
  # Only process subjects that have posterior draws 
  subjects <- intersect(unique(original_data$Subject),
                        unique(draws_wide$Subject))
  
  # Calculate fitted values for each subject 
  fit_list <- lapply(subjects, 
                     fit_subject, 
                     draws_wide = draws_wide, 
                     original_data = original_data, 
                     decay_type = decay_type, 
                     min_value = min_value) 
  
  # Combine summarized results 
  dplyr::bind_rows(fit_list)
  
  return(fit_list)
}
