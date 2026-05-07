#' @title Default print for [serodynamics::run_mod()] output object of class
#' `sr_model`
#' @description
#' A default print method for class `sr_model` that prints posterior medians
#' for antibody kinetic curve parameters by `Iso_type` and
#' `Stratification` (if specified).
#' @param x An `sr_model` output object from [run_mod()].
#' @param print_tbl A [logical] indicator to print `x` in the style of a
#'   [tibble::tbl_df].
#' @param ... Additional arguments passed to the print method.
#' @returns Invisibly returns either:
#' \itemize{
#'   \item when `print_tbl = TRUE`, a tibble containing the raw `sr_model`
#'   draws;
#'   \item otherwise, a data summary containing posterior medians for
#'   antibody kinetic curve parameters by `Iso_type` and `Stratification`
#'   (if specified).
#' }
#' @export
#' @examples
#' print(nepal_sees_jags_output)
print.sr_model <- function(x, 
                           print_tbl = FALSE,
                           ...) { # nolint
  if (print_tbl) {
    x <- dplyr::as_tibble(x)
    print(x)
    invisible(x)
  } else {
    cat("An sr_model with the following median values:")
    cat("\n")
    cat("\n")
    # Suppress only the known pivot_wider() warning when column names come
    # from model parameters (e.g. "alpha", "shape", etc.) with no naming
    # conflict issues, while leaving other warnings visible.
    x <- x |>
      dplyr::filter(.data$Subject == "newperson") |>
      dplyr::summarise(.by = c("Stratification", "Iso_type", "Parameter"),
                       median_val = stats::median(.data$value)) |>
      (\(data) {
        suppressWarnings(
          tidyr::pivot_wider(data,
                             names_from = "Parameter",
                             values_from = "median_val")
        )
      })() |>
      dplyr::arrange(.data$Iso_type)
    # Taking out stratification column if not specified
    # "None" is the sentinel value used when no stratification variable is
    # specified in run_mod(); see the `strat` argument in run_mod().
    if (!"Stratification" %in% names(x) || all(x$Stratification == "None", 
                                               na.rm = TRUE)) {
      x <- dplyr::select(x, -dplyr::any_of("Stratification"))
    }
    print(as.data.frame(x))
    invisible(x)
  } 
}
