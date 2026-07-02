# Computes predicted antibody curves over a grid of time points from
# posterior parameter samples, then summarises them to a median + 95%
# credible interval per antigen-isotype/stratification/time combination.
summarize_serocurve_samples <- function(param_samples, antigen_iso_col,
                                         xlim) {
  # Clamp the grid to `xlim` when supplied to avoid unnecessary computation
  # outside the visible range.
  if (!is.null(xlim)) {
    tx <- seq(xlim[1], xlim[2], by = 5)
  } else {
    tx <- seq(0, 1200, by = 5)
  }

  serocurve_all <- param_samples |>
    dplyr::reframe(
      t = .env$tx,
      res = ab(.data$t, .data$y0, .data$y1, .data$t1, .data$alpha,
               .data$shape),
      .by = all_of(
        c("Chain", "Iteration", antigen_iso_col, "Stratification")
      )
    )

  serocurve_all |>
    dplyr::summarise(
      .by = all_of(c(antigen_iso_col, "Stratification", "t")),
      res_med  = stats::quantile(.data$res, probs = 0.50, na.rm = TRUE),
      res_low  = stats::quantile(.data$res, probs = 0.025, na.rm = TRUE),
      res_high = stats::quantile(.data$res, probs = 0.975, na.rm = TRUE)
    )
}
