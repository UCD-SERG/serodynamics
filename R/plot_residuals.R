#' @title Plot Residuals Over Time
#' @description
#' Plots residuals over time and facets by antigen-isotype (`Iso_type`). The
#' mean absolute residual for each facet is annotated in the upper-right
#' corner.
#' Fitted and residual values are calculated on demand via [calc_fit_mod()],
#' using the `original_data` and `strat` attributes stored on `model` by
#' [run_serodynamics()], and include both natural-scale and log10-scale
#' medians and 2.5%/97.5% posterior quantiles.
#' @param model An `sr_model` object (returned by [run_serodynamics()]), with
#' `original_data` and `strat` attributes (see [calc_fit_mod()]).
#' @param ids (Optional) Participant IDs to include. When supplied, points
#' (and, if `connect_lines = TRUE`, lines) are colored by subject; otherwise
#' no color is used.
#' @param antigen_isos (Optional) Antigen-isotypes (`antigen_iso`) to include.
#' @param log_y [logical]; if `TRUE` (default), plots the residual computed on
#' the log10 scale (`log10(observed) - log10(fitted)`); if `FALSE`, plots the
#' natural-scale residual.
#' @param show_interval [logical]; if `TRUE` (default), draws an error bar
#' around each residual spanning its 2.5%/97.5% posterior interval, to
#' visualize the precision of the posterior.
#' @param connect_lines [logical]; if `TRUE`, connects each subject's
#' residuals over time with a line. Default `FALSE`.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @example inst/examples/examples-plot_residuals.R
plot_residuals <- function(model,
                           ids = NULL,
                           antigen_isos = NULL,
                           log_y = TRUE,
                           show_interval = TRUE,
                           connect_lines = FALSE) {
  if (!inherits(model, "sr_model")) {
    cli::cli_abort("{.arg model} must be an {.cls sr_model} object.")
  }

  original_data <- attr(model, "original_data")
  if (is.null(original_data)) {
    cli::cli_abort(c(
      "x" = "{.arg model} has no {.val original_data} attribute.",
      "i" = "Use output from {.fn run_serodynamics}."
    ))
  }

  strat <- attr(model, "strat")
  if (is.null(strat)) {
    strat <- NA
  }

  fit_res <- calc_fit_mod(
    modeled_dat = model,
    original_data = original_data,
    strat = strat
  )

  to_plot <- residuals_from_fit_res(fit_res, ids, antigen_isos, log_y) |>
    dplyr::arrange(.data$Subject, .data$Iso_type, .data$t)

  ylab <- if (log_y) {
    "Residual (log10(observed) - log10(fitted))"
  } else {
    "Residual (observed - fitted)"
  }

  colored <- !is.null(ids)

  p <- to_plot |>
    ggplot2::ggplot(
      ggplot2::aes(x = .data$t, y = .data$resid_med, group = .data$Subject)
    ) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.5, linetype = "dashed")

  if (show_interval) {
    p <- p +
      ggplot2::geom_errorbar(
        ggplot2::aes(ymin = .data$resid_low, ymax = .data$resid_high),
        linewidth = 0.4, width = 0, alpha = 0.5, na.rm = TRUE
      )
  }

  if (colored) {
    p <- p + ggplot2::geom_point(ggplot2::aes(color = .data$Subject),
                                 alpha = 0.6)
  } else {
    p <- p + ggplot2::geom_point(alpha = 0.6)
  }

  if (connect_lines) {
    p <- if (colored) {
      p + ggplot2::geom_line(ggplot2::aes(color = .data$Subject), alpha = 0.5)
    } else {
      p + ggplot2::geom_line(alpha = 0.5)
    }
  }

  p <- p +
    ggplot2::facet_wrap(ggplot2::vars(.data$Iso_type)) +
    ggplot2::geom_text(
      data = mae_label_data(to_plot),
      mapping = ggplot2::aes(x = Inf, y = Inf, label = .data$label),
      hjust = 1.1, vjust = 1.5, size = 3.2, inherit.aes = FALSE
    ) +
    ggplot2::theme_bw() +
    ggplot2::xlab("Time since seroconversion (days)") +
    ggplot2::ylab(ylab)

  if (colored) {
    p <- p + ggplot2::guides(color = "none")
  }

  return(p)
}

# One row per `Iso_type` giving a "MAE = ..." label, for annotating each
# facet with its mean absolute residual.
mae_label_data <- function(to_plot) {
  mae <- to_plot |>
    dplyr::summarise(
      .by = all_of("Iso_type"),
      mae = mean(abs(.data$resid_med), na.rm = TRUE)
    )

  mae |>
    dplyr::mutate(label = paste("MAE =", signif(.data$mae, 3)))
}
