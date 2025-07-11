#' @title Generate Predicted Antibody Response Curves (Median + 95% CI)
#' @description
#' Plots a median antibody response curve with a 95% credible interval 
#' ribbon, using full posterior samples. Optionally overlays observed data, 
#' moves the legend to the bottom, provides options to apply log10 
#' transformation on the y- and x-axes, and to show all individual 
#' sampled curves.
#'
#' @param jags_post A [dplyr::tbl_df] returned by `run_mod(...)` containing the
#'   full posterior parameter samples.
#' @param id           The original subject ID (e.g. "sees_npl_128") to extract.
#' @param antigen_iso  The antigen to extract, e.g. "HlyE_IgA" or "HlyE_IgG".
#' @param dataset (Optional) A tibble with observed antibody response data. 
#' Must contain:
#'   - `timeindays`
#'   - `value`
#'   - `id`
#'   - `antigen_iso`
#' @param legend_obs Label for observed data in the legend.
#' @param legend_mod1 Label for the median prediction line.
#' @param show_quantiles logical; if TRUE (default), plots the 2.5%, 50%, 
#' and 97.5% quantiles.
#' @param log_scale logical; if TRUE, applies a log10 transformation to 
#' the y-axis.
#' @param log_x [logical]; if TRUE, applies a log10 transformation to the 
#' x-axis.
#' @param show_all_curves logical; if TRUE, overlays all 
#' individual sampled curves.
#' @param alpha_samples Numeric; transparency level for individual 
#' curves (default = 0.3).
#' @param xlim (Optional) A numeric vector of length 2 providing custom x-axis 
#' limits.
#'
#' @return A [ggplot2::ggplot] object displaying predicted antibody response 
#' curves with a median curve and a 95% credible interval band as default.
#' @export
#'
#' @example inst/examples/examples-plot_predicted_curve.R
plot_predicted_curve <- function(jags_post,
                                 id,
                                 antigen_iso,
                                 dataset = NULL,
                                 legend_obs = "Observed data",
                                 legend_mod1 = "Median prediction",
                                 show_quantiles = TRUE,
                                 log_scale = FALSE,
                                 log_x = FALSE,
                                 show_all_curves = FALSE,
                                 alpha_samples = 0.3,
                                 xlim = NULL) {
  
  # --------------------------------------------------------------------------
  # 1) The 'jags_post' object is now the tibble itself
  df <- jags_post
  
  
  # --------------------------------------------------------------------------
  # 2) Filter to the subject & antigen of interest:
  df_sub   <- df |>
    dplyr::filter(
      .data$Subject == id,        # e.g. "sees_npl_128"
      .data$Iso_type == antigen_iso  # e.g. "HlyE_IgA"
    )
  
  # --------------------------------------------------------------------------
  # 3) Clean up parameter name if you like:
  df_clean <- df_sub |>
    dplyr::mutate(
      Parameter_clean = stringr::str_extract(.data$Parameter, "^[^\\[]+")
    )
  
  # --------------------------------------------------------------------------
  # 4) Pivot to wide format: one row per iteration/chain
  param_medians_wide <- df_clean |>
    dplyr::select(
      all_of(c("Chain",
               "Iteration",
               "Iso_type",
               "Parameter_clean",
               "value"))
    ) |>
    tidyr::pivot_wider(
      names_from  = c("Parameter_clean"),
      values_from = c("value")
    ) |>
    dplyr::arrange(.data$Chain, .data$Iteration) |>
    
    dplyr::mutate(
      antigen_iso = factor(.data$Iso_type),
      r = .data$shape
    ) |>
    dplyr::select(-c("Iso_type"))
  
  # Ensure Subject column exists in each model's data
  if (!"Subject" %in% names(param_medians_wide)) {
    param_medians_wide <- param_medians_wide |>
      dplyr::mutate(Subject = "subject1")
  }

  # Add sample_id if not present (to identify individual samples)
  if (!"sample_id" %in% names(param_medians_wide)) {
    param_medians_wide <- param_medians_wide |>
      dplyr::mutate(sample_id = dplyr::row_number())
  }
  # Define time points for prediction
  tx2 <- seq(0, 1200, by = 5)
  
  # Antibody response model function
  ab <- function(t, y0, y1, t1, alpha, shape) {
    beta <- log(y1 / y0) / t1
    if (t <= t1) {
      y0 * exp(beta * t)
    } else {
      (y1^(1 - shape) - (1 - shape) * alpha * (t - t1))^(1 / (1 - shape))
    }
  }
  
  ## --- Prepare data for Model 1 ---
  dt1 <- data.frame(t = tx2) |>
    dplyr::mutate(id = dplyr::row_number()) |>
    tidyr::pivot_wider(names_from = c("id"), 
                       values_from = c("t"), 
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
  
  # Base ggplot object with legend at the bottom.
  p <- ggplot2::ggplot() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Days since fever onset", y = "ELISA units") +
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
  color_labels <- c("median" = legend_mod1)
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
      labels = color_labels
    ) +
    ggplot2::scale_fill_manual(
      name = "Component",
      values = fill_vals,
      labels = fill_labels,
      guide = ggplot2::guide_legend(override.aes = list(color = NA))
    )
  
  # --- Optionally add log10 scales for y and/or x ---
  if (log_scale) {
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
