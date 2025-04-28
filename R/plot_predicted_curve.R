#' @title Generate Predicted Antibody Response Curves (Median + 95% CI)
#' @description
#' Plots a single median antibody response curve with a 95% credible interval 
#' ribbon, using full posterior samples. Optionally overlays observed data, 
#' moves the legend to the bottom, provides options to apply log10 
#' transformation on the y- and x-axes, and to show all individual 
#' sampled curves.
#'
#' @param param_medians_wide A tibble with full posterior parameter samples 
#' (first model).
#' @param param_medians_wide2 (Optional) A tibble with full posterior 
#' parameter samples (second model).
#'   If this tibble contains observed data (with "dayssincefeveronset"), 
#'   it will be treated as the observed data, and only one model is plotted.
#' @param dataset (Optional) A tibble with observed antibody response data. 
#' Must contain:
#'   - `timeindays`
#'   - `value`
#'   - `id`
#'   - `antigen_iso`
#' @param legend_obs Label for observed data in the legend.
#' @param legend_mod1 Label for the first model in the legend.
#' @param legend_mod2 Label for the second model in the legend.
#' @param show_quantiles Logical; if TRUE (default), plots the 2.5%, 50%, 
#' and 97.5% quantiles.
#' @param log_scale Logical; if TRUE, applies a log10 transformation to 
#' the y-axis.
#' @param log_x Logical; if TRUE, applies a log10 transformation to the x-axis.
#' @param show_all_curves Logical; if TRUE, overlays all 
#' individual sampled curves.
#' @param alpha_samples Numeric; transparency level for individual 
#' curves (default = 0.3).
#'
#' @return A ggplot object displaying predicted antibody response curves 
#' with a median curve and a 95% credible interval band.
#' @export
#'
#' @examples
#' # 1) Prepare the on-the-fly dataset
#' dataset <- serodynamics::nepal_sees |>
#'   as_case_data(
#'     id_var        = "id",
#'     biomarker_var = "antigen_iso",
#'     value_var     = "value",
#'     time_in_days  = "timeindays"
#'   ) |>
#'   rename(
#'     strat      = bldculres,
#'     timeindays = dayssincefeveronset,
#'     value      = result
#'   )
#'
#' # 2) Extract just the one subject/antigen for overlay later
#' dat <- dataset |>
#'   filter(id == "sees_npl_128", antigen_iso == "HlyE_IgA")
#'
#' # 3) Fit the model to the full dataset
#' model <- run_mod(
#'   data         = dataset,
#'   file_mod     = serodynamics_example("model.jags"),
#'   nchain       = 2,
#'   nadapt       = 100,
#'   nburn        = 100,
#'   nmc          = 500,
#'   niter        = 1000,
#'   strat        = "strat",
#'   include_subs = TRUE
#' )
#'
#' # 4) Pull out the full MCMC samples for that one ID + antigen
#' full_samples <- process_jags_samples(
#'   jags_post   = model,
#'   dataset     = dataset,
#'   id          = "sees_npl_128",
#'   antigen_iso = "HlyE_IgA"
#' )
#'
#' # 5a) Plot (linear axes) with all individual curves + median ribbon
#' p1 <- plot_predicted_curve(
#'   param_medians_wide = full_samples,
#'   dataset                = dat,
#'   legend_obs         = "Observed Data",
#'   legend_mod1        = "Full Model Predictions",
#'   show_quantiles     = TRUE,
#'   log_scale          = FALSE,
#'   log_x              = FALSE,
#'   show_all_curves    = TRUE
#' )
#' print(p1)
#'
#' # 5b) Plot (log10 y-axis) with all individual curves + median ribbon
#' p2 <- plot_predicted_curve(
#'   param_medians_wide = full_samples,
#'   dataset                = dat,
#'   legend_obs         = "Observed Data",
#'   legend_mod1        = "Full Model Predictions",
#'   show_quantiles     = TRUE,
#'   log_scale          = TRUE,
#'   log_x              = FALSE,
#'   show_all_curves    = TRUE
#' )
#' print(p2)
plot_predicted_curve <- function(param_medians_wide,
                                 param_medians_wide2 = NULL,
                                 dataset = NULL,
                                 legend_obs = "Observed Data",
                                 legend_mod1 = "Model 1 Predictions",
                                 legend_mod2 = "Model 2 Predictions",
                                 show_quantiles = TRUE,
                                 log_scale = FALSE,
                                 log_x = FALSE,
                                 show_all_curves = FALSE,
                                 alpha_samples = 0.3) {
  
  # If the second argument is actually observed data, treat it as 'dat'
  if (!is.null(param_medians_wide2) && "timeindays" %in% 
        names(param_medians_wide2)) {
    dataset <- param_medians_wide2
    param_medians_wide2 <- NULL
  }
  
  # Ensure Subject column exists in each model's data
  if (!"Subject" %in% names(param_medians_wide)) {
    param_medians_wide <- param_medians_wide |>
      dplyr::mutate(Subject = "subject1")
  }
  if (!is.null(param_medians_wide2) && !"Subject" %in% 
        names(param_medians_wide2)) {
    param_medians_wide2 <- param_medians_wide2 |>
      dplyr::mutate(Subject = "subject2")
  }
  
  # Add sample_id if not present (to identify individual samples)
  if (!"sample_id" %in% names(param_medians_wide)) {
    param_medians_wide <- param_medians_wide |>
      dplyr::mutate(sample_id = dplyr::row_number())
  }
  if (!is.null(param_medians_wide2) && !"sample_id" %in% 
        names(param_medians_wide2)) {
    param_medians_wide2 <- param_medians_wide2 |>
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
    tidyr::pivot_wider(names_from = .data$id, 
                       values_from = .data$t, 
                       names_prefix = "time") |>
    dplyr::slice(
      rep(seq_len(dplyr::n()), each = nrow(param_medians_wide))
    )
  
  
  serocourse_all1 <- cbind(param_medians_wide, dt1) |>
    tidyr::pivot_longer(cols = dplyr::starts_with("time"), values_to = "t") |>
    dplyr::select(-.data$name) |>
    dplyr::rowwise() |>
    dplyr::mutate(res = ab(.data$t, 
                           .data$y0, 
                           .data$y1, 
                           .data$t1, 
                           .data$alpha, 
                           .data$shape)) |>
    dplyr::ungroup()
  
  ## --- Prepare data for Model 2 (if provided) ---
  if (!is.null(param_medians_wide2)) {
    dt2 <- data.frame(t = tx2) |>
      dplyr::mutate(id = dplyr::row_number()) |>
      tidyr::pivot_wider(names_from = .data$id, 
                         values_from = .data$t, 
                         names_prefix = "time") |>
      dplyr::slice(
        rep(seq_len(dplyr::n()), each = nrow(param_medians_wide2))
      )
    
    
    serocourse_all2 <- cbind(param_medians_wide2, dt2) |>
      tidyr::pivot_longer(cols = dplyr::starts_with("time"), 
                          values_to = "t") |>
      dplyr::select(-.data$name) |>
      dplyr::rowwise() |>
      dplyr::mutate(res = ab(.data$t, 
                             .data$y0, 
                             .data$y1, 
                             .data$t1, 
                             .data$alpha, 
                             .data$shape)) |>
      dplyr::ungroup()
  }
  
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
                                      group = .data$sample_id),
                         color = "gray", alpha = 0.2)
    if (!is.null(param_medians_wide2)) {
      p <- p +
        ggplot2::geom_line(data = serocourse_all2,
                           ggplot2::aes(x = .data$t, 
                                        y = .data$res, 
                                        group = .data$sample_id),
                           color = "gray", alpha = 0.2)
    }
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
                                        fill = "mod1"),
                           alpha = 0.2, inherit.aes = FALSE) +
      ggplot2::geom_line(data = sum1,
                         ggplot2::aes(x = .data$t, 
                                      y = .data$res.med, 
                                      color = "mod1"),
                         size = 1, inherit.aes = FALSE)
  }
  
  # --- Summarize & Plot Model 2 (Median + 95% Ribbon) ---
  if (!is.null(param_medians_wide2) && show_quantiles) {
    sum2 <- serocourse_all2 |>
      dplyr::group_by(t) |>
      dplyr::summarise(
        res.med  = stats::quantile(.data$res, probs = 0.50, na.rm = TRUE),
        res.low  = stats::quantile(.data$res, probs = 0.025, na.rm = TRUE),
        res.high = stats::quantile(.data$res, probs = 0.975, na.rm = TRUE),
        .groups  = "drop"
      )
    
    p <- p +
      ggplot2::geom_ribbon(data = sum2,
                           ggplot2::aes(x = .data$t, 
                                        ymin = .data$res.low, 
                                        ymax = .data$res.high, 
                                        fill = "mod2"),
                           alpha = 0.2, inherit.aes = FALSE) +
      ggplot2::geom_line(data = sum2,
                         ggplot2::aes(x = .data$t, 
                                      y = .data$res.med, 
                                      color = "mod2"),
                         size = 1, inherit.aes = FALSE)
  }
  
  # --- Overlay Observed Data (if provided) ---
  if (!is.null(dataset)) {
    observed_data <- dataset |>
      dplyr::rename(t = .data$timeindays, 
                    res = .data$value) |>
      dplyr::select(.data$id, 
                    .data$t, 
                    .data$res, 
                    .data$antigen_iso) |>
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
  color_vals <- c("mod1" = "red")
  color_labels <- c("mod1" = legend_mod1)
  fill_vals  <- c("mod1" = "red")
  fill_labels <- c("mod1" = legend_mod1)
  
  if (!is.null(param_medians_wide2)) {
    color_vals["mod2"] <- "green"
    color_labels["mod2"] <- legend_mod2
    fill_vals["mod2"] <- "green"
    fill_labels["mod2"] <- legend_mod2
  }
  if (!is.null(dataset)) {
    color_vals["observed"] <- "blue"
    color_labels["observed"] <- legend_obs
  }
  
  p <- p +
    ggplot2::scale_color_manual(values = color_vals,
                                labels = color_labels,
                                name = "Data Type") +
    ggplot2::scale_fill_manual(values = fill_vals,
                               labels = fill_labels,
                               guide = "none")
  
  # --- Optionally add log10 scales for y and/or x ---
  if (log_scale) {
    p <- p + ggplot2::scale_y_log10()
  }
  if (log_x) {
    p <- p + ggplot2::scale_x_log10()
  }
  
  return(p)
}
