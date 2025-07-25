#' @title Generate Predicted Antibody Response Curves (Median + 95% CI)
#' @description
#' Plots a median antibody response curve with a 95% credible interval 
#' ribbon, using MCMC samples from the posterior distribution. 
#' Optionally overlays observed data, 
#' applies logarithmic spacing on the y- and x-axes, 
#' and shows all individual 
#' sampled curves.
#'
#' @param sr_model An `sr_model` object (returned by [run_mod()]) containing 
#'   samples from the posterior distribution of the model parameters.
#' @param id The participant ID to plot; for example, "sees_npl_128".
#' @param antigen_iso  The antigen isotype to plot; for example, "HlyE_IgA" or 
#' "HlyE_IgG".
#' @param dataset (Optional) A [dplyr::tbl_df] with observed antibody response 
#' data. 
#' Must contain:
#'   - `timeindays`
#'   - `value`
#'   - `id`
#'   - `antigen_iso`
#' @param legend_obs Label for observed data in the legend.
#' @param legend_median Label for the median prediction line.
#' @param show_quantiles [logical]; if [TRUE] (default), plots the 2.5%, 50%, 
#' and 97.5% quantiles.
#' @param log_y [logical]; if [TRUE], applies a [log10] transformation to 
#' the y-axis.
#' @param log_x [logical]; if [TRUE], applies a [log10] transformation to the 
#' x-axis.
#' @param show_all_curves [logical]; if [TRUE], overlays all 
#' individual sampled curves.
#' @param alpha_samples Numeric; transparency level for individual 
#' curves (default = 0.3).
#' @param xlim (Optional) A numeric vector of length 2 providing custom x-axis 
#' limits.
#' @param ylab (Optional) A string for the y-axis label. If `NULL` (default), 
#' the label is automatically set to "ELISA units" or "ELISA units (log scale)"
#' based on the `log_y` argument.
#'
#' @return A [ggplot2::ggplot] object displaying predicted antibody response 
#' curves with a median curve and a 95% credible interval band as default.
#' @export
#'
#' @example inst/examples/examples-plot_predicted_curve.R
plot_predicted_curve <- function(sr_model,
                                 id,
                                 antigen_iso,
                                 dataset = NULL,
                                 legend_obs = "Observed data",
                                 legend_median = "Median prediction",
                                 show_quantiles = TRUE,
                                 log_y = FALSE,
                                 log_x = FALSE,
                                 show_all_curves = FALSE,
                                 alpha_samples = 0.3,
                                 xlim = NULL,
                                 ylab = NULL) {
  
  # --------------------------------------------------------------------------
  # 1) The 'sr_model' object is now the tibble itself
  df <- sr_model
  
  
  # --------------------------------------------------------------------------
  # 2) Filter to the subject & antigen of interest:
  df_sub   <- df |>
    dplyr::filter(
      .data$Subject == id,        # e.g. "sees_npl_128"
      .data$Iso_type == antigen_iso  # e.g. "HlyE_IgA"
    )
  
  # --------------------------------------------------------------------------
  # 3) Pivot to wide format: one row per iteration/chain
  param_medians_wide <- df_sub |>
    dplyr::select(
      all_of(c("Chain",
               "Iteration",
               "Iso_type",
               "Parameter",
               "value"))
    ) |>
    tidyr::pivot_wider(
      names_from  = c("Parameter"),
      values_from = c("value")
    ) |>
    dplyr::arrange(.data$Chain, .data$Iteration) |>
    
    dplyr::mutate(
      antigen_iso = factor(.data$Iso_type),
      r = .data$shape
    ) |>
    dplyr::select(-c("Iso_type"))

  # Add sample_id if not present (to identify individual samples)
  if (!"sample_id" %in% names(param_medians_wide)) {
    param_medians_wide <- param_medians_wide |>
      dplyr::mutate(sample_id = dplyr::row_number())
  }
  # Define time points for prediction
  tx2 <- seq(0, 1200, by = 5)
  
  
  ## --- Prepare data for Model 1 ---
  dt1 <- data.frame(t = tx2) |>
    dplyr::mutate(id = dplyr::row_number()) |>
    tidyr::pivot_wider(names_from = "id", 
                       values_from = "t", 
                       names_prefix = "time") |>
    dplyr::slice(
      rep(seq_len(dplyr::n()), each = nrow(param_medians_wide))
    )
  
  
  serocourse_all1 <- cbind(param_medians_wide, dt1) |>
    tidyr::pivot_longer(cols = dplyr::starts_with("time"), values_to = "t") |>
    dplyr::select(-c("name")) |>
    dplyr::rowwise() |>
    dplyr::mutate(res = ab(.data$t, 
                           .data$y0, 
                           .data$y1, 
                           .data$t1, 
                           .data$alpha, 
                           .data$shape)) |>
    dplyr::ungroup()
  
  # Determine Y-axis label
  if (is.null(ylab)) {
    if (log_y) {
      ylab <- "ELISA units (log scale)"
    } else {
      ylab <- "ELISA units"
    }
  }
  
  # Base ggplot object with legend at the bottom.
  p <- ggplot2::ggplot() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Days since fever onset", y = ylab) +
    ggplot2::theme(legend.position = "bottom")
  
  # If show_all_curves is TRUE, overlay all individual sampled curves.
  if (show_all_curves) {
    p <- p +
      ggplot2::geom_line(data = serocourse_all1,
                         ggplot2::aes(x = .data$t, 
                                      y = .data$res, 
                                      group = .data$sample_id,
                                      color = "samples"),
                         alpha = alpha_samples)
  }
  
  # --- Summarize & Plot Model 1 (Median + 95% Ribbon) ---
  if (show_quantiles) {
    sum1 <- serocourse_all1 |>
      dplyr::group_by(t) |>
      dplyr::summarise(
        res.med  = stats::quantile(.data$res, probs = 0.50, na.rm = TRUE),
        res.low  = stats::quantile(.data$res, probs = 0.025, na.rm = TRUE),
        res.high = stats::quantile(.data$res, probs = 0.975, na.rm = TRUE),
        .groups  = "drop"
      )
    
    p <- p +
      ggplot2::geom_ribbon(data = sum1,
                           ggplot2::aes(x = .data$t, 
                                        ymin = .data$res.low, 
                                        ymax = .data$res.high, 
                                        fill = "ci"),
                           alpha = 0.2, inherit.aes = FALSE) +
      ggplot2::geom_line(data = sum1,
                         ggplot2::aes(x = .data$t, 
                                      y = .data$res.med, 
                                      color = "median"),
                         linewidth = 1, inherit.aes = FALSE)
  }
  
  # --- Overlay Observed Data (if provided) ---
  if (!is.null(dataset)) {
    observed_data <- dataset |>
      dplyr::rename(t = c("timeindays"), 
                    res = c("value")) |>
      dplyr::select(all_of(c("id", 
                             "t",
                             "res",
                             "antigen_iso"))) |>
      dplyr::mutate(id = as.factor(.data$id))
    
    p <- p +
      ggplot2::geom_point(data = observed_data,
                          ggplot2::aes(x = .data$t, 
                                       y = .data$res, 
                                       group = .data$id, 
                                       color = "observed"),
                          size = 2, show.legend = TRUE) +
      ggplot2::geom_line(data = observed_data,
                         ggplot2::aes(x = .data$t, 
                                      y = .data$res, 
                                      group = .data$id, 
                                      color = "observed"),
                         linewidth = 1, show.legend = TRUE)
  }
  
  # --- Construct Unified Legend ---
  color_vals <- c("median" = "red")
  color_labels <- c("median" = legend_median)
  fill_vals <- c("ci" = "red")
  fill_labels <- c("ci" = "95% credible interval")

  if (show_all_curves) {
    color_vals["samples"] <- "gray"
    color_labels["samples"] <- "Posterior samples"
  }

  if (!is.null(dataset)) {
    color_vals["observed"] <- "blue"
    color_labels["observed"] <- legend_obs
  }
  
  p <- p +
    ggplot2::scale_color_manual(
      name = "Component",
      values = color_vals,
      labels = color_labels,
      guide = ggplot2::guide_legend(override.aes = list(shape = NA))
    ) +
    ggplot2::scale_fill_manual(
      name = "Component",
      values = fill_vals,
      labels = fill_labels,
      guide = ggplot2::guide_legend(override.aes = list(color = NA))
    )
  
  # --- Optionally add log10 scales for y and/or x ---
  if (log_y) {
    p <- p + ggplot2::scale_y_log10()
  }
  if (log_x) {
    p <- p +
      ggplot2::scale_x_continuous(
        trans = scales::pseudo_log_trans(sigma = 1, base = 10)
      )
  }
  
  # --- Set custom x-axis limits if provided ---
  if (!is.null(xlim)) {
    p <- p + ggplot2::coord_cartesian(xlim = xlim)
  }

  return(p)
}
