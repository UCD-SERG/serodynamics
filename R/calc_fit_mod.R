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
                         strat = NA) {

original_data <- original_data |>
      use_att_names() |>
      select(
         any_of(
           "Subject", 
           "Iso_type", 
           "t",
           "result",
           "Stratification" = strat
         )
      )
    # Rename strat column to "Stratification" (no-op if already named so),
    # guarding against a name collision when the input already has a
    # "Stratification" column distinct from `strat`.
    if (strat != "Stratification") {
      original_data <- original_data |>
        dplyr::rename("Stratification" = dplyr::all_of(strat))
    }
  }

  # Preparing modeled data
  modeled_dat <- modeled_dat |>
    dplyr::summarize(.by = c(.data$Parameter, .data$Iso_type,
                             .data$Stratification,
                             .data$Subject),
                     med_value = stats::median(.data$value)) |>
    tidyr::pivot_wider(names_from = .data$Parameter,
                       values_from = .data$med_value)

  # Matching input data with modeled data
  if (is.na(strat)) {
    matched_dat <- merge(modeled_dat, original_data,
                         by = c("Subject", "Iso_type"),
                         all.y = TRUE)
  } else {
    matched_dat <- merge(modeled_dat, original_data,
                         by = c("Subject", "Iso_type", "Stratification"),
                         all.y = TRUE)
  }

  # Calculating fitted and residual
  fitted_dat <- matched_dat |>
    mutate(fitted = ab(.data$t, .data$y0, .data$y1, .data$t1,
                       .data$alpha, .data$shape),
           residual = .data$result - .data$fitted) |>
    select(.data$Subject, .data$Iso_type, .data$Stratification,
           .data$t, .data$fitted, .data$residual)
  fitted_dat
}
