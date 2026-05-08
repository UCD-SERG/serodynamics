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
#' @return Invisibly returns either:
#' \itemize{
#'   \item When `print_tbl = TRUE`, a tibble containing the raw `sr_model`
#'   draws;
#'   \item Otherwise, a data summary containing posterior medians for
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
    print(tibble::as_tibble(x), ...)
  } else {
    cat("An sr_model with the following median values:")
    cat("\n")
    cat("\n")
    summary_tbl <- x |>
      dplyr::filter(.data$Subject == "newperson") |>
      dplyr::summarise(.by = c("Stratification", "Iso_type", "Parameter"),
                       median_val = stats::median(.data$value)) |>
      tidyr::pivot_wider(names_from = "Parameter",
                         values_from = "median_val") |>
      dplyr::arrange(.data$Iso_type)
    # Taking out stratification column if not specified
    # "None" is the sentinel value used when no stratification variable is
    # specified in run_mod(); see the `strat` argument in run_mod().
    if (!"Stratification" %in% names(summary_tbl) ||
        all(summary_tbl$Stratification == "None", na.rm = TRUE)) {
      summary_tbl <- dplyr::select(summary_tbl, -dplyr::any_of("Stratification"))
    }
    print(as.data.frame(summary_tbl), ...)
  }
  invisible(x)
}
