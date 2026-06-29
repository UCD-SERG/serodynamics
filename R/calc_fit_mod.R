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
#' @param decay_type A [character] string specifying the decay function
#'   (`"power"` or `"exponential"`). Passed through to [ab()]. Default is
#'   `"power"`.
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
                         strat = NA,
                         decay_type = "power") {
  strat_col <- if (is.na(strat)) character() else c(Stratification = strat)

  original_data <- original_data |>
    use_att_names() |>
    dplyr::select(
      dplyr::any_of(c("Subject", "Iso_type", "t", "result", strat_col))
    )

  # Preparing modeled data
  modeled_dat <- modeled_dat |>
    dplyr::summarize(
      .by = dplyr::all_of(
        c("Parameter", "Iso_type", "Stratification", "Subject")
      ),
      med_value = stats::median(.data$value)
    ) |>
    tidyr::pivot_wider(names_from = "Parameter", values_from = "med_value")

  # Matching input data with modeled data
  matched_dat <- modeled_dat |>
    dplyr::right_join(
      original_data,
      by = base::intersect(
        c("Subject", "Iso_type", "Stratification"),
        names(original_data)
      ),
      relationship = "one-to-many"
    )

  # Calculating fitted and residual
  fitted_dat <- matched_dat |>
    dplyr::mutate(
      fitted = ab(.data$t, .data$y0, .data$y1, .data$t1,
                  .data$alpha, .data$shape,
                  decay_type = decay_type),
      residual = .data$result - .data$fitted
    ) |>
    dplyr::select(
      dplyr::all_of(
        c("Subject", "Iso_type", "Stratification", "t", "fitted", "residual")
      )
    )

  return(fitted_dat)
}
