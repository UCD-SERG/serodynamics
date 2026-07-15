#' @title Plot Residuals Over Time
#' @description
#' Plots residuals over time and facets by antigen-isotype (`Iso_type`). The
#' mean absolute residual for each facet is annotated in the upper-right
#' corner.
#'
#' If `dataset` is supplied, residuals are computed using posterior draws from
#' `model`, producing a median residual with a 95% interval for each
#' observation.
#' If `dataset` is `NULL`, residuals are taken from
#' `attr(model, "fitted_residuals")` (computed in [run_serodynamics()] via
#' [calc_fit_mod()]), along with the 2.5%/97.5% posterior quantiles stored
#' alongside them. These are always on the natural (non-log) scale, regardless
#' of `log_y`. `fitted_residuals` attributes created before this interval was
#' added lack those quantile columns; residuals from such objects are plotted
#' without an interval.
#'
#' @param model An `sr_model` object (returned by [run_mod()]).
#' @param dataset (Optional) A `case_data` (or compatible) data frame used to
#' compute observation-level residual intervals.
#' @param ids (Optional) Participant IDs to include.
#' @param antigen_isos (Optional) Antigen-isotypes (`antigen_iso`) to include.
#' @param log_y [logical]; if `TRUE` (default), computes residuals on the
#' log10-scale as `log10(pred) - log10(obs)`. Only applies when `dataset` is
#' supplied.
#' @param min_value [numeric]; minimum value used when `log_y = TRUE` to avoid
#' `-Inf` from `log10(0)`.
#' @param probs A numeric vector of length 3 giving the lower, median, and
#' upper probabilities for residual intervals. Only used when `dataset` is
#' supplied.
#' @param n_draws (Optional) Maximum number of posterior draws to use per
#' subject and antigen-isotype. Use this to speed up plotting for large
#' objects.
#' @param show_interval [logical]; if `TRUE` (default), draws an error bar
#' around each residual spanning its `probs` interval, to visualize the
#' precision of the posterior.
#' @param connect_lines [logical]; if `TRUE`, connects each subject's
#' residuals over time with a line. Default `FALSE`.
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @example inst/examples/examples-plot_residuals.R
plot_residuals <- function(model,
                           dataset = NULL,
                           ids = NULL,
                           antigen_isos = NULL,
                           log_y = TRUE,
                           min_value = 0.01,
                           probs = c(0.025, 0.5, 0.975),
                           n_draws = NULL,
                           show_interval = TRUE,
                           connect_lines = FALSE) {
  probs <- sort(probs)
  params_needed <- c("y0", "y1", "t1", "alpha", "shape")
  validate_residuals_inputs(model, probs, n_draws, params_needed)

  to_plot <- if (is.null(dataset)) {
    residuals_from_fit_res(model, ids, antigen_isos)
  } else {
    residuals_from_draws(
      model, dataset, ids, antigen_isos,
      log_y, min_value, probs, n_draws, params_needed
    )
  }

  to_plot <- to_plot |>
    dplyr::arrange(.data$Subject, .data$Iso_type, .data$t)

  ylab <- if (log_y) {
    "Residual (log10(pred) - log10(obs))"
  } else {
    "Residual (pred - obs)"
  }

  p <- to_plot |>
    ggplot2::ggplot(
      ggplot2::aes(x = .data$t, y = .data$resid_med, group = .data$Subject)
    ) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.5, linetype = "dashed")

  if (show_interval) {
    p <- p +
      ggplot2::geom_errorbar(
        ggplot2::aes(ymin = .data$resid_low, ymax = .data$resid_high),
        linewidth = 0.4,
        width = 0,
        alpha = 0.5,
        na.rm = TRUE
      )
  }

  p <- p +
    ggplot2::geom_point(ggplot2::aes(color = .data$Subject), alpha = 0.6)

  if (connect_lines) {
    p <- p +
      ggplot2::geom_line(ggplot2::aes(color = .data$Subject), alpha = 0.5)
  }

  p +
    ggplot2::facet_wrap(ggplot2::vars(.data$Iso_type)) +
    ggplot2::geom_text(
      data = mae_label_data(to_plot),
      mapping = ggplot2::aes(x = Inf, y = Inf, label = .data$label),
      hjust = 1.1,
      vjust = 1.5,
      size = 3.2,
      inherit.aes = FALSE
    ) +
    ggplot2::guides(color = "none") +
    ggplot2::theme_bw() +
    ggplot2::xlab("Time since seroconversion (days)") +
    ggplot2::ylab(ylab)
}

validate_residuals_inputs <- function(model, probs, n_draws, params_needed) {
  if (length(probs) != 3) {
    cli::cli_abort("{.arg probs} must have length 3.")
  }

  if (any(probs < 0 | probs > 1)) {
    cli::cli_abort("{.arg probs} values must be between 0 and 1.")
  }

  if (!is.null(n_draws) && (!is.numeric(n_draws) || length(n_draws) != 1)) {
    cli::cli_abort("{.arg n_draws} must be a single number or `NULL`.")
  }

  if (!is.null(n_draws) && n_draws < 1) {
    cli::cli_abort("{.arg n_draws} must be >= 1.")
  }

  if (!inherits(model, "sr_model")) {
    cli::cli_abort("{.arg model} must be an {.cls sr_model} object.")
  }

  if (!all(params_needed %in% unique(model$Parameter))) {
    cli::cli_abort(c(
      "x" = "{.arg model} is missing required parameters.",
      "i" = "Needed: {.field {params_needed}}",
      "i" = "Found: {.field {unique(model$Parameter)}}"
    ))
  }
}

# Residuals (and their posterior quantiles) from `attr(model,
# "fitted_residuals")`, for when no `dataset` is supplied.
residuals_from_fit_res <- function(model, ids, antigen_isos) {
  fit_res <- attr(model, "fitted_residuals")
  if (is.null(fit_res)) {
    cli::cli_abort(c(
      "x" = paste(
        "{.arg dataset} is `NULL` and {.arg model} has no",
        "{.val fitted_residuals} attribute."
      ),
      "i" = paste(
        "Pass the original dataset via {.arg dataset} or use output from",
        "{.fn run_mod}."
      )
    ))
  }

  fit_res <- tibble::as_tibble(fit_res)
  if (!all(c("residual_low", "residual_high") %in% names(fit_res))) {
    fit_res$residual_low <- NA_real_
    fit_res$residual_high <- NA_real_
  }

  to_plot <- fit_res |>
    dplyr::mutate(
      resid_low = -.data$residual_high,
      resid_med = -.data$residual,
      resid_high = -.data$residual_low
    )

  if (!is.null(ids)) {
    to_plot <- to_plot |>
      dplyr::filter(.data$Subject %in% .env$ids)
  }

  if (!is.null(antigen_isos)) {
    to_plot <- to_plot |>
      dplyr::filter(.data$Iso_type %in% .env$antigen_isos)
  }

  to_plot |>
    dplyr::select(
      all_of(c(
        "Subject", "Iso_type", "t", "resid_low", "resid_med", "resid_high"
      ))
    )
}

# Residuals computed from posterior draws matched against an observed
# `dataset`, for when `dataset` is supplied.
residuals_from_draws <- function(model,
                                 dataset,
                                 ids,
                                 antigen_isos,
                                 log_y,
                                 min_value,
                                 probs,
                                 n_draws,
                                 params_needed) {
  obs <- dataset |>
    tibble::as_tibble() |>
    use_att_names() |>
    dplyr::mutate(.obs_row = dplyr::row_number()) |>
    dplyr::select(all_of(c(".obs_row", "Subject", "Iso_type", "t", "result")))

  model_sub <- model |>
    dplyr::filter(.data$Parameter %in% .env$params_needed)

  if (!is.null(ids)) {
    obs <- obs |> dplyr::filter(.data$Subject %in% .env$ids)
    model_sub <- model_sub |> dplyr::filter(.data$Subject %in% .env$ids)
  }

  if (!is.null(antigen_isos)) {
    obs <- obs |> dplyr::filter(.data$Iso_type %in% .env$antigen_isos)
    model_sub <- model_sub |>
      dplyr::filter(.data$Iso_type %in% .env$antigen_isos)
  }

  param_wide <- model_sub |>
    dplyr::select(
      all_of(c(
        "Iteration", "Chain", "Subject", "Iso_type", "Parameter", "value"
      ))
    ) |>
    tidyr::pivot_wider(names_from = "Parameter", values_from = "value")

  if (!is.null(n_draws)) {
    param_wide <- param_wide |>
      dplyr::group_by(.data$Subject, .data$Iso_type) |>
      dplyr::group_modify(function(data, key) {
        dplyr::slice_sample(
          .data = data,
          n = min(as.integer(n_draws), nrow(data))
        )
      }) |>
      dplyr::ungroup()
  }

  resid_draws <- obs |>
    dplyr::inner_join(
      param_wide,
      by = c("Subject", "Iso_type"),
      relationship = "many-to-many"
    ) |>
    dplyr::mutate(
      pred = ab(
        t = .data$t,
        y0 = .data$y0,
        y1 = .data$y1,
        t1 = .data$t1,
        alpha = .data$alpha,
        shape = .data$shape
      )
    )

  resid_draws <- if (log_y) {
    resid_draws |>
      dplyr::mutate(
        resid = log10(pmax(.data$pred, .env$min_value)) -
          log10(pmax(.data$result, .env$min_value))
      )
  } else {
    resid_draws |>
      dplyr::mutate(resid = .data$pred - .data$result)
  }

  resid_draws |>
    dplyr::summarise(
      .by = all_of(c(".obs_row", "Subject", "Iso_type", "t")),
      resid_low = stats::quantile(
        .data$resid, probs = .env$probs[1], na.rm = TRUE
      ),
      resid_med = stats::quantile(
        .data$resid, probs = .env$probs[2], na.rm = TRUE
      ),
      resid_high = stats::quantile(
        .data$resid, probs = .env$probs[3], na.rm = TRUE
      )
    ) |>
    dplyr::select(-".obs_row")
}

# One row per `Iso_type` giving a "MAE = ..." label, for annotating each
# facet with its mean absolute residual.
mae_label_data <- function(to_plot) {
  mae <- to_plot |>
    dplyr::summarise(
      .by = "Iso_type",
      mae = mean(abs(.data$resid_med), na.rm = TRUE)
    )

  mae |>
    dplyr::mutate(label = paste("MAE =", signif(.data$mae, 3)))
}
