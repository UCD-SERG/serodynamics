#' @title Calculates fitted and residual values for modeled outputs
#' @description
#'  `calc_fit_mod()` takes antibody kinetic parameter estimates and calculates
#'  fitted and residual values. Fitted values correspond to the estimated assay
#'  value (ex. ELISA units etc.) at time since infection (TSI). Residual values
#'  are calculate as the difference between fitted and observed values.
#' @param input_dat A [] dataframe of modeled antibody kinetic parameter values.
#' @param original_data A [] data frame of the original input dataset.
#' @returns A [data.frame] attached as an [attributes] with the following
#' values:
#'   - Subject = ID number specifying an individual
#'   - Iso_type = The modeled antigen_isotype
#'   - t = Time since infection 
#'   - fitted = The fitted value calculated using model output parameters for a
#'   given `t`
#'   - residual = The residual value calculated as the difference between
#'   observed and fitted values for a given `t`

calc_fit_mod <- function(input_dat = jags_out, 
                         original_data = orig_data) {
  # Preparing modeled data
  input_dat <- input_dat |>
    dplyr::group_by(.data$Parameter, .data$Iso_type, .data$Stratification, 
                    .data$Subject) |>
    dplyr::summarize(med_value = median(.data$value)) |>
    tidyr::spread(.data$Parameter, .data$med_value)

  # Matching input data with modeled data
  matched_dat <- merge(input_dat, original_data, by = c("Subject", "Iso_type"),
                       all.y = TRUE)

  # Calculating fitted and residual
  fitted_dat <- matched_dat |>
    mutate(fitted = ifelse(.data$t <= .data$t1, 
                           .data$y0 * exp((log(.data$y1 / .data$y0) / .data$t1)
                                          * .data$t),
                           (.data$y1 ^ (1 - shape) - (1 - .data$shape) *
                              .data$alpha * (.data$t - .data$t1)) ^ 
                             (1 / (1 - .data$shape))),
           residual = .data$result - .data$fitted) |>
    select(.data$Subject, .data$Iso_type, .data$t, .data$fitted, .data$residual)
}
