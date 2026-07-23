#' @title Extracts Residuals from Attributes
#' @description
#' Takes residuals (and their posterior quantiles), on the requested scale,
#' from `attr(model, "fitted_residuals")`.
#' @param model An `sr_model` object with a `fitted_residuals` attribute.
#' @param ids (Optional) Participant IDs to include.
#' @param antigen_isos (Optional) Antigen-isotypes (`antigen_iso`) to include.
#' @param log_y [logical]; if `TRUE`, use log10-scale residuals; if `FALSE`, use
#'   natural-scale residuals.
#' @return A [tibble::tbl_df] ready to plot.
#' @keywords internal
residuals_from_fit_res <- function(model, ids, antigen_isos, log_y) {
  fit_res <- attr(model, "fitted_residuals")
  if (is.null(fit_res)) {
    cli::cli_abort(c(
      "x" = "{.arg model} has no {.val fitted_residuals} attribute.",
      "i" = "Use output from {.fn run_serodynamics}."
    ))
  }
  
  fit_res <- tibble::as_tibble(fit_res)
  
  cols <- if (log_y) {
    c(
      low = "log_residual_low", med = "log_residual", high = "log_residual_high"
    )
  } else {
    c(low = "residual_low", med = "residual", high = "residual_high")
  }
  for (col in setdiff(cols, names(fit_res))) {
    fit_res[[col]] <- NA_real_
  }
  
  to_plot <- fit_res |>
    dplyr::mutate(
      resid_low = .data[[cols[["low"]]]],
      resid_med = .data[[cols[["med"]]]],
      resid_high = .data[[cols[["high"]]]]
    )
  
  if (!is.null(ids)) {
    to_plot <- to_plot |>
      dplyr::filter(.data$Subject %in% .env$ids)
  }
  
  if (!is.null(antigen_isos)) {
    to_plot <- to_plot |>
      dplyr::filter(.data$Iso_type %in% .env$antigen_isos)
  }
  
  p <- to_plot |>
    dplyr::select(
      all_of(c(
        "Subject", "Iso_type", "t", "resid_low", "resid_med", "resid_high"
      ))
    )
  return(p)
} 
