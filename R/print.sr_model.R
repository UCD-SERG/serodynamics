#' @title Default print for [serodynamics::run_mod()] output object of class
#' `sr_model`
#' @description
#'  A default print method for class `sr_model` that includes the median
#'  posterior distribution for antibody kinetic curve parameters by `Iso_type`
#'  and `Stratification` (if specified).
#' @param x An `sr_model` output object from [run_mod()].
#' @param print_tbl A [logical] indicator to print in style of [dplyr::tbl_df].
#' @param ... Additional arguments affecting the summary produced.
#' [serodynamics::run_mod()] function.
#' @returns A data summary that
#' contains the mean posterior distribution for antibody kinetic curve
#' parameters by `Iso_type` and `Stratification` (if specified).
#' @export
#' @examples
#' print(nepal_sees_jags_output)
print.sr_model <- function(x, 
                           print_tbl = FALSE,
                           ...) { # nolint
  if (print_tbl) {
    x <- dplyr::as_tibble(x)
    print(x)
  } else {
    cat("An sr_model with the following median values:")
    cat("\n")
    cat("\n")
    x <- x |>
      dplyr::summarise(.by = c(.data$Stratification, .data$Iso_type, 
                               .data$Parameter), 
                       median_val = stats::median(.data$value)) |>
      tidyr::pivot_wider(names_from = .data$Parameter, 
                         values_from = .data$median_val) |>
      dplyr::arrange(.data$Iso_type) |>
      suppressWarnings()
    # Taking out stratification column if not specified
    if (unique(x$Stratification == "None")) {
      x <- x |> select(-c(.data$Stratification))
    } 
    print(as.data.frame(x))
    invisible(x)
  } 
}
