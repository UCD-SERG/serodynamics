#' @title Creates Plot for Estimated Serodynamic Curves
#' @description
#' Assembles the full `plot_serocurve()` ggplot object (bands, faceting,
#' log scales, and custom x-axis limits) from a summarised curve tibble.
#' @return A [ggplot2::ggplot] object.
#' @keywords internal
build_serocurve_plot <- function(curve_summary, show_ci, multi_strat,
                                 antigen_iso,
                                 antigen_iso_col, log_y, log_x, xlim,
                                 facet_by_strat,
                                 ...) {
  p <- ggplot2::ggplot() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Time since onset", y = "Assay result") +
    ggplot2::theme(legend.position = "bottom")

  p <- add_serocurve_bands(
    p, curve_summary, show_ci, multi_strat, ...
    )
  p <- add_serocurve_facets(
    p, curve_summary, 
    facet_by_strat = facet_by_strat,
    antigen_iso = antigen_iso, 
    antigen_iso_col, ...
  )

  if (log_y) {
    p <- p + ggplot2::scale_y_log10()
  }
  if (log_x) {
    p <- p +
      ggplot2::scale_x_continuous(
        transform = scales::pseudo_log_trans(sigma = 1, base = 10)
      )
  }
  if (!is.null(xlim)) {
    p <- p + ggplot2::coord_cartesian(xlim = xlim)
  }

  p
}
