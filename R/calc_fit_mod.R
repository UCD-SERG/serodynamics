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
#'   - fitted = The median (across posterior draws) fitted value for a given
#'   `t`
#'   - residual = The median (across posterior draws) residual, calculated as
#'   the difference between observed and fitted values for a given `t`
#'   - residual_low, residual_high = The 2.5% and 97.5% quantiles (across
#'   posterior draws) of the residual, giving a precision interval around
#'   `residual`
#'
#'   Rows from `original_data` whose stratification value is `NA` are retained
#'   in the output with `NA` `fitted` and `residual` values, since no posterior
#'   estimate is available for those (Subject, Iso_type, Stratification)
#'   tuples.
#' @keywords internal
calc_fit_mod <- function(modeled_dat,
                         original_data,
                         strat = NA) {
  strat_col <- if (is.na(strat)) character() else c(Stratification = strat)

  original_data <- original_data |>
    use_att_names() |>
    dplyr::mutate(.obs_row = dplyr::row_number()) |>
    dplyr::select(
      dplyr::any_of(c(
        ".obs_row", "Subject", "Iso_type", "t", "result", strat_col
      ))
    )

  # Wide-format posterior draws: one row per iteration/chain/subject/iso.
  draws_wide <- modeled_dat |>
    dplyr::select(
      dplyr::all_of(c(
        "Iteration", "Chain", "Subject", "Iso_type", "Stratification",
        "Parameter", "value"
      ))
    ) |>
    tidyr::pivot_wider(names_from = "Parameter", values_from = "value")

  # Matching input data with modeled draws (many draws per observation)
  matched_dat <- draws_wide |>
    dplyr::right_join(
      original_data,
      by = base::intersect(
        c("Subject", "Iso_type", "Stratification"),
        names(original_data)
      ),
      relationship = "many-to-many"
    )

  # Calculating per-draw fitted and residual values, then summarizing each
  # observation's median fitted/residual and 2.5%/97.5% residual quantiles.
  fitted_dat <- matched_dat |>
    dplyr::mutate(
      fitted = ab(.data$t, .data$y0, .data$y1, .data$t1,
                  .data$alpha, .data$shape),
      residual = .data$result - .data$fitted
    ) |>
    dplyr::summarise(
      .by = dplyr::all_of(
        c(".obs_row", "Subject", "Iso_type", "Stratification", "t")
      ),
      fitted = stats::median(.data$fitted, na.rm = TRUE),
      residual_low = quantile_or_na(.data$residual, 0.025),
      residual_high = quantile_or_na(.data$residual, 0.975),
      residual_med = stats::median(.data$residual, na.rm = TRUE)
    ) |>
    dplyr::rename(residual = "residual_med") |>
    dplyr::select(
      dplyr::all_of(
        c("Subject", "Iso_type", "Stratification", "t",
          "fitted", "residual", "residual_low", "residual_high")
      )
    )

  return(fitted_dat)
}

# 2.5%/97.5%-style quantile that returns `NA` instead of erroring when `x`
# has no non-missing values (e.g. an unmatched right-joined observation).
quantile_or_na <- function(x, probs) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(NA_real_)
  }
  stats::quantile(x, probs = probs, names = FALSE)
}
