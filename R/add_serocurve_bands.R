# Adds the median line (and, if `show_ci`, the 95% credible interval
# ribbon) to a `plot_serocurve()` plot, coloured/filled by Stratification
# when `multi_strat` is TRUE and by a fixed "median"/"ci" legend entry
# otherwise.
add_serocurve_bands <- function(p, curve_summary, show_ci, multi_strat) {
  if (show_ci) {
    p <- p +
      ggplot2::geom_ribbon(
        data = curve_summary,
        ggplot2::aes(
          x = .data$t,
          ymin = .data$res_low,
          ymax = .data$res_high,
          fill = if (multi_strat) .data$Stratification else "ci"
        ),
        alpha = 0.2,
        inherit.aes = FALSE
      )
  }

  p <- p +
    ggplot2::geom_line(
      data = curve_summary,
      ggplot2::aes(
        x = .data$t,
        y = .data$res_med,
        colour = if (multi_strat) .data$Stratification else "median"
      ),
      linewidth = 1,
      inherit.aes = FALSE
    )

  if (multi_strat) {
    return(p)
  }

  # ---- Legend for single-stratification plots ----------------------------
  color_vals <- c("median" = "red")
  color_labels <- c("median" = "Median")

  p <- p +
    ggplot2::scale_color_manual(
      name = "",
      values = color_vals,
      labels = color_labels,
      guide = ggplot2::guide_legend(override.aes = list(shape = NA))
    )

  if (show_ci) {
    fill_vals <- c("ci" = "red")
    fill_labels <- c("ci" = "95% credible interval")

    p <- p +
      ggplot2::scale_fill_manual(
        name = "",
        values = fill_vals,
        labels = fill_labels,
        guide = ggplot2::guide_legend(override.aes = list(color = NA))
      )
  }

  p
}
