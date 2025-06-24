#' @title Calculates fitted values for run_mod output
#' @description
#'  `calc_fit_mod()` takes antibody kinetic parameters and creates a fitted
#'  value corresponding to the estimated assay value (ex. ELISA units etc.) at
#'  time since infection (TSI).
#' @param t A [vector] of time points used to plot the fitted values.
#' @returns A [vector] of fitted
#'  value corresponding to the estimated assay value (ex. ELISA units etc.) at
#'  time since infection (TSI).
#' @export
#' @example inst/examples/run_mod-examples.R

calc_fit_mod <- function(input_dat = jags_out, 
                         org_data = dl_sub) {
  # Matching time_since_infection from original data set.
  input_dat <- input_dat |>
    dplyr::group_by(.data$Parameter, .data$Iso_type, .data$Stratification, 
                    .data$Subject) |>
    dplyr::summarize(med_value = median(.data$value)) |>
    tidyr::spread(.data$Parameter, .data$med_value)

  # Preparing input data to match time
  org_data <- dl_sub |>
    rename(Subject = attributes(dl_sub)$id_var,
           Iso_type = attributes(dl_sub)$biomarker_var,
           t = attributes(dl_sub)$timeindays,
           result = attributes(dl_sub)$value_var) |>
    select(.data$Subject, .data$Iso_type, .data$t, .data$result)

  # Matching input data with modeled data
  matched_dat <- merge(input_dat, org_data, by = c("Subject", "Iso_type"),
                       all.y = TRUE)

  # Calculating fitted and residual
  fitted_dat <- matched_dat |>
    mutate(fitted = ifelse(.data$t <= .data$t1, 
                           .data$y0 * exp((log(.data$y1 / .data$y0) / .data$t1)
                                          * .data$t),
                           (.data$y1 ^ (1 - shape) - (1 - .data$shape) *
                              .data$alpha * (.data$t - .data$t1)) ^ 
                             (1 / (1 - .data$shape)),
                           residual = .data$result - .data$fitted) |>
    select(.data$Subject, .data$Iso_type, .data$t, .data$fitted, .data$residual)
    }
