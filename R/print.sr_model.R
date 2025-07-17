#' @title Default print for [serodynamics::run_mod()] output object of class
#' `sr_model`
#' @description
#'  A default print method for class `sr_model` that includes the mean posterior
#'  distribution for antibody kinetic curve parameters by `Iso_type` and
#'  `Stratification` (if specified).
#' @param x An `sr_model` output object from [run_mod()].
#' @param ... Additional arguments affecting the summary produced.
#' [serodynamics::run_mod()] function.
#' @returns A [dplyr::grouped_df] that
#' contains the mean posterior distribution for antibody kinetic curve
#' parameters by `Iso_type` and `Stratification` (if specified).
#' @export
#' @examples
#' print(nepal_sees_jags_output)
print.sr_model <- function(x, ...) { # nolint
  x <- x |>
    dplyr::group_by(.data$Stratification, .data$Iso_type, .data$Parameter) |>
    dplyr::summarise(mean_val = mean(.data$value)) |>
    tidyr::pivot_wider(names_from = .data$Parameter, 
                       values_from = .data$mean_val) |>
    dplyr::arrange(.data$Iso_type)
  # Taking out stratification column if not specified
  if (unique(data$Stratification == "None")) {
    x <- x |> select(-all_of(Stratification))
  } 
  invisible(x)
}
