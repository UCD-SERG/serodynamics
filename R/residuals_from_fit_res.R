#' @title Extracts Residuals for Plotting
#' @description
#' Filters and reshapes fitted/residual values (and their posterior
#' quantiles), on the requested scale, for plotting.
#' @param fit_res A [data.frame] of fitted and residual values, as returned by
#' [calc_fit_mod()].
#' @param ids (Optional) Participant IDs to include.
#' @param antigen_isos (Optional) Antigen-isotypes (`antigen_iso`) to include.
#' @param log_y [logical]; if `TRUE`, use log10-scale residuals; if `FALSE`, use
#'   natural-scale residuals.
#' @return A [tibble::tbl_df] ready to plot.
#' @keywords internal
residuals_from_fit_res <- function(fit_res, ids, antigen_isos, log_y) {
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
