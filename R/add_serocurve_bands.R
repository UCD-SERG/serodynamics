# Adds the median line (and, if `show_ci`, the 95% credible interval
# ribbon) to a `plot_serocurve()` plot, coloured/filled by Stratification
# when `multi_strat` is TRUE and by a fixed "median"/"ci" legend entry
# otherwise.
add_serocurve_bands <- function(p, curve_summary, show_ci, multi_strat, ...) {
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
    p <- p +
      ggplot2::labs(colour = "Stratification", fill = "Stratification")
  } else {
    p <- p +
      ggplot2::scale_colour_manual(
        name = "",
        values = c(median = "red"),
        labels = c(median = "Median"),
        guide = ggplot2::guide_legend(order = 1,
                                      override.aes = list(shape = NA))
      )

    if (show_ci) {
      p <- p +
        ggplot2::scale_fill_manual(
          name = "",
          values = c(ci = "red"),
          labels = c(ci = "95% credible interval"),
          guide = ggplot2::guide_legend(order = 2,
                                        override.aes = list(colour = NA))
        )
    }
  }

  p
}
