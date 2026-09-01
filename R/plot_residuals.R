#' @title Plot Residuals Over Time
#' @description
#' Plots residuals over time and facets by antigen-isotype (`Iso_type`). The
#' mean absolute residual for each facet is annotated in the upper-right
#' corner.
#' Fitted and residual values are calculated on demand via [calc_fit_mod()],
#' using the `original_data`, `strat`, and `decay_type` attributes stored on
#' `model` by [run_serodynamics()], and include both natural-scale and
#' log10-scale medians and 2.5%/97.5% posterior quantiles.
#' @param model An `sr_model` object (returned by [run_serodynamics()]), with
#' `original_data`, `strat`, and `decay_type` attributes (see
#' [calc_fit_mod()]).
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
#' @param facet_by_strat [character]; facets residual plot and 
#' calculates MAE by specified stratification variable. Default `NULL`.
#' @param color_by_strat [character]; colors residual plot and 
#' calculates MAE by specified stratification variable. Default `NULL`.
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
                           connect_lines = FALSE,
                           facet_by_strat = NULL,
                           color_by_strat = NULL) {
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

  decay_type <- attr(model, "decay_type")
  if (is.null(decay_type)) {
    decay_type <- "power"
  }

  fit_res <- calc_fit_mod(
    modeled_dat = model,
    original_data = original_data,
    strat = strat,
    decay_type = decay_type
  )

  to_plot <- residuals_from_fit_res(fit_res, ids, antigen_isos, log_y) |>
    dplyr::arrange(.data$Subject, .data$Iso_type, .data$t)

  ylab <- if (log_y) {
    "Residual (log10(observed) - log10(fitted))"
  } else {
    "Residual (observed - fitted)"
  }

  colored <- !is.null(ids)
  color_strat <- !is.null(color_by_strat)
  facet_strat <- !is.null(facet_by_strat)
  
  # ------------------------------------------------------------
  # Setting up stratification
  # ------------------------------------------------------------
  
  if (color_strat || facet_strat) {
    strat_cols <- c(if (color_strat) color_by_strat,
                    if (facet_strat) facet_by_strat)

    id_var <- attr(original_data, "id_var")
    
    strat_data <- original_data |>
      dplyr::select(dplyr::all_of(unique(c(id_var, strat_cols)))) |>
      dplyr::rename(Subject = dplyr::all_of(id_var)) |>
      dplyr::distinct()
    
    to_plot <- to_plot |>
      dplyr::left_join(strat_data, by = "Subject")
  }
  
  # ------------------------------------------------------------
  # Determine color variable
  # ------------------------------------------------------------
  if (colored) {
    color_var <- "Subject"
    legend_position <- "right"
  } else if (color_strat) {
    color_var <- color_by_strat
    legend_position <- "top"
  } else {
    color_var <- NULL
    legend_position <- "none"
  }
  
  p <- to_plot |>
    ggplot2::ggplot(ggplot2::aes(x = .data$t, y = .data$resid_med, 
                                 group = .data$Subject)) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.5, linetype = "dashed")

  if (show_interval) {
    p <- p +
      ggplot2::geom_errorbar(
        ggplot2::aes(ymin = .data$resid_low, ymax = .data$resid_high),
        linewidth = 0.4, width = 0, alpha = 0.5, na.rm = TRUE
      )
  }
  # ------------------------------------------------------------
  # Points
  # ------------------------------------------------------------
  if (colored) {
    p <- p +
      ggplot2::geom_point(ggplot2::aes(color = .data$Subject),
                          alpha = 0.6) +
      ggplot2::labs(color = "Subject") +
      ggplot2::theme(legend.position = "right")
    
  } else if (color_strat) {
    p <- p +
      ggplot2::geom_point(ggplot2::aes(color = !!rlang::sym(color_by_strat)),
                          alpha = 0.6) +
      ggplot2::labs(color = color_by_strat) +
      ggplot2::theme(legend.position = "top")
  } else {
    p <- p + ggplot2::geom_point(alpha = 0.6)
  }
  
  if (!is.null(color_by_strat) && is.null(colored)) {
    p <- p + ggplot2::geom_point(ggplot2::aes(color = .data$Subject),
                                 alpha = 0.6) +
      ggplot2::theme(legend.position = "top")
  }
  # ------------------------------------------------------------
  # Connecting lines
  # ------------------------------------------------------------
  if (connect_lines) {
    if (!is.null(color_var)) {
      p <- p +
        ggplot2::geom_line(ggplot2::aes(color = !!rlang::sym(color_var)),
                           alpha = 0.5)
    } else {
      p + ggplot2::geom_line(alpha = 0.5)
    }
  }
  
  # ------------------------------------------------------------
  # Faceting
  # ------------------------------------------------------------
  if (facet_strat) {
    facet_formula <- stats::as.formula(paste("~ Iso_type +", facet_by_strat))
  } else {
    facet_formula <- ~Iso_type
  }
  p <- p +
    ggplot2::facet_wrap(facet_formula) 
  
  # ------------------------------------------------------------
  # MAE labels
  # ------------------------------------------------------------
  p <- p +
    ggplot2::geom_text(
                       data = mae_label_data(to_plot, facet_by_strat),
                       mapping = ggplot2::aes(x = Inf, y = Inf, 
                                              label = .data$label),
                       hjust = 1.1, vjust = 1.5, size = 3.2, 
                       inherit.aes = FALSE) 
    
  # ------------------------------------------------------------
  # Theme
  # ------------------------------------------------------------
  p <- p +
    ggplot2::theme_bw() +
    ggplot2::xlab("Time since seroconversion (days)") +
    ggplot2::ylab(ylab) +
    ggplot2::theme(legend.position = legend_position)
  
  return(p)
}

# One row per `Iso_type` giving a "MAE = ..." label, for annotating each
# facet with its mean absolute residual.
mae_label_data <- function(to_plot, facet_by_strat = NULL) {
  group_vars <- c(
    "Iso_type",
    if (!is.null(facet_by_strat)) facet_by_strat
  )
  mae <- to_plot |>
    dplyr::summarise(
      .by = dplyr::all_of(group_vars),
      mae = mean(abs(.data$resid_med), na.rm = TRUE)
    )

  mae <- mae |>
    dplyr::mutate(label = paste("MAE =", signif(.data$mae, 3)))
  return(mae)
}
