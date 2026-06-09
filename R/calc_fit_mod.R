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
#' @returns A [data.frame] attached as an [attributes] with the following
#' values:
#'   - Subject = ID number specifying an individual
#'   - Iso_type = The modeled antigen_isotype
#'   - Stratification = The variable used to stratify the model
#'   (`"None"` when no stratification is used)
#'   - t = Time since infection
#'   - fitted = The fitted value calculated using model output parameters for a
#'   given `t`
#'   - residual = The residual value calculated as the difference between
#'   observed and fitted values for a given `t`
#'
#'   Rows from `original_data` whose stratification value is `NA` are retained
#'   in the output with `NA` `fitted` and `residual` values, since no posterior
#'   estimate is available for those (Subject, Iso_type, Stratification)
#'   tuples.
#' @keywords internal
calc_fit_mod <- function(modeled_dat, 
                         original_data,
                         strat = strat) {
  original_data <- original_data |>
    use_att_names() |>
    dplyr::rename(Stratification = dplyr::any_of(if (is.na(strat)) character() 
                                                 else strat)) |>
    dplyr::select(any_of(c("Subject", "Iso_type", "t", "result", 
                           "Stratification")))

  # Preparing modeled data
  modeled_dat <- modeled_dat |>
    dplyr::summarize(.by = c("Parameter", "Iso_type",
                             "Stratification", "Subject"),
                     med_value = stats::median(.data$value)) |>
    tidyr::pivot_wider(names_from = "Parameter",
                       values_from = "med_value")

  # Matching input data with modeled data
  by_vars <- c("Subject", "Iso_type")
  if ("Stratification" %in% names(original_data)) {
    by_vars <- c(by_vars, "Stratification")
  }
  matched_dat <- modeled_dat |>
    dplyr::right_join(
      original_data,
      by = by_vars
    )

  # Calculating fitted and residual
  fitted_dat <- matched_dat |>
    mutate(fitted = ab(.data$t, .data$y0, .data$y1, .data$t1,
                       .data$alpha, .data$shape),
           residual = .data$result - .data$fitted) |>
    select(all_of(c("Subject", "Iso_type", "Stratification", 
                    "t", "fitted", "residual")))
  fitted_dat
}
