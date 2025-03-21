#' @title Generate Predicted Antibody Response Curves
#' @author Kwan Ho Lee
#' @description
#' Uses median parameter estimates to plot predicted antibody response curves.
#' If observed data is provided, it overlays the observed values as points and
#' connects them with lines.
#' 
#' @importFrom stringr str_extract
#'
#' @param param_medians_wide A tibble with median parameter estimates (first model).
#' @param param_medians_wide2 (Optional) A tibble with median parameter estimates (second model).
#' Alternatively, if this tibble contains observed data (e.g., with a column "dayssincefeveronset"),
#' it will be treated as the observed data, and only one predicted curve will be plotted.
#' @param dat (Optional) A tibble with observed antibody response data.
#' It must contain `dayssincefeveronset`, `result`, `id`, and `antigen_iso`.
#' @param legend_obs A character string for the observed data legend label (default: "Observed Data").
#' @param legend_mod1 A character string for the first model's legend label (default: "").
#' If empty, no legend key is shown.
#' @param legend_mod2 A character string for the second model's legend label (default: "").
#' If empty, no legend key is shown.
#' @return A ggplot object displaying predicted antibody response curves.  
#' If two parameter sets are provided, the first is plotted in red and the second in green.
#' Observed data (if provided) are shown in blue.
#' @export
#' 
#' @examples
#' # Ensure JAGS is available before running
#' if (!is.element(runjags::findjags(), c("", NULL))) {
#'
#'   # Prepare dataset & Run JAGS Model
#'   jags_results <- prepare_and_run_jags(
#'     id = "sees_npl_128",
#'     antigen_iso = "HlyE_IgA"
#'   )
#'
#'   # Process JAGS output (step 7)
#'   param_medians_wide_128 <- process_jags_output(
#'     jags_post   = jags_results$nepal_sees_jags_post,
#'     dataset     = jags_results$dataset,
#'     run_until   = 7
#'   )
#'
#'   # Generate and print predicted antibody response curve
#'   plot_pred_only <- plot_predicted_curve(param_medians_wide_128)
#'   print(plot_pred_only)
#' }
#'
plot_predicted_curve <- function(param_medians_wide, param_medians_wide2 = NULL, dat = NULL,
                                 legend_obs = "Observed Data",
                                 legend_mod1 = "",
                                 legend_mod2 = "") {
  
  # If the second argument appears to be observed data (has "dayssincefeveronset"),
  # then treat it as 'dat' and set param_medians_wide2 to NULL.
  if (!is.null(param_medians_wide2) && "dayssincefeveronset" %in% names(param_medians_wide2)) {
    dat <- param_medians_wide2
    param_medians_wide2 <- NULL
  }
  
  # Define the time sequence for prediction
  tx2 <- seq(0, 1200, by = 5)  
  
  # Antibody response model function
  ab <- function(t, y0, y1, t1, alpha, shape) {
    beta <- log(y1 / y0) / t1
    yt <- ifelse(t <= t1, 
                 y0 * exp(beta * t),
                 (y1^(1 - shape) - (1 - shape) * alpha * (t - t1))^(1 / (1 - shape)))
    return(yt)
  }
  
  # Compute predicted curves for the first median parameter set (mod1)
  dT1 <- data.frame(t = tx2) %>%
    dplyr::mutate(ID = dplyr::row_number()) %>%
    tidyr::pivot_wider(names_from = ID, values_from = t, names_prefix = "time") %>%
    dplyr::slice(rep(1:nrow(.), each = nrow(param_medians_wide)))
  
  serocourse_all1 <- cbind(param_medians_wide, dT1) %>%
    tidyr::pivot_longer(cols = dplyr::starts_with("time"), values_to = "t") %>%
    dplyr::select(-name) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(res = ab(t, y0, y1, t1, alpha, shape)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(id = as.factor(Subject))
  
  # Compute predicted curves for the second median parameter set (mod2), if provided
  if (!is.null(param_medians_wide2)) {
    dT2 <- data.frame(t = tx2) %>%
      dplyr::mutate(ID = dplyr::row_number()) %>%
      tidyr::pivot_wider(names_from = ID, values_from = t, names_prefix = "time") %>%
      dplyr::slice(rep(1:nrow(.), each = nrow(param_medians_wide2)))
    
    serocourse_all2 <- cbind(param_medians_wide2, dT2) %>%
      tidyr::pivot_longer(cols = dplyr::starts_with("time"), values_to = "t") %>%
      dplyr::select(-name) %>%
      dplyr::rowwise() %>%
      dplyr::mutate(res = ab(t, y0, y1, t1, alpha, shape)) %>%
      dplyr::ungroup() %>%
      dplyr::mutate(id = as.factor(Subject))
  }
  
  # Initialize the base plot
  p <- ggplot2::ggplot() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Days since fever onset", y = "ELISA units", color = "Data Type") +
    ggplot2::theme(legend.position = "right")
  
  # Add predicted curve for the first median parameter set (mod1)
  if (legend_mod1 != "") {
    p <- p + ggplot2::geom_line(data = serocourse_all1,
                                ggplot2::aes(x = t, y = res, group = id, color = "mod1"),
                                alpha = 0.3, show.legend = TRUE)
  } else {
    p <- p + ggplot2::geom_line(data = serocourse_all1,
                                ggplot2::aes(x = t, y = res, group = id),
                                color = "red", alpha = 0.3, show.legend = FALSE)
  }
  
  # Add predicted curve for the second median parameter set (mod2), if provided
  if (!is.null(param_medians_wide2)) {
    if (legend_mod2 != "") {
      p <- p + ggplot2::geom_line(data = serocourse_all2,
                                  ggplot2::aes(x = t, y = res, group = id, color = "mod2"),
                                  alpha = 0.3, show.legend = TRUE)
    } else {
      p <- p + ggplot2::geom_line(data = serocourse_all2,
                                  ggplot2::aes(x = t, y = res, group = id),
                                  color = "green", alpha = 0.3, show.legend = FALSE)
    }
  }
  
  # Overlay observed data if provided (always map color to get a legend key)
  if (!is.null(dat)) {
    observed_data <- dat %>%
      dplyr::rename(t = dayssincefeveronset, res = result) %>%
      dplyr::select(id, t, res, antigen_iso) %>%
      dplyr::mutate(id = as.factor(id))
    
    p <- p +
      ggplot2::geom_point(data = observed_data,
                          ggplot2::aes(x = t, y = res, group = id, color = "observed"),
                          size = 2, show.legend = TRUE) +
      ggplot2::geom_line(data = observed_data,
                         ggplot2::aes(x = t, y = res, group = id, color = "observed"),
                         linewidth = 1, show.legend = TRUE)
  }
  
  # Construct the color scale manually based on which legend items are active.
  color_vals <- c()
  color_labels <- c()
  
  if (legend_mod1 != "") {
    color_vals["mod1"] <- "red"
    color_labels["mod1"] <- legend_mod1
  }
  if (!is.null(param_medians_wide2) && legend_mod2 != "") {
    color_vals["mod2"] <- "green"
    color_labels["mod2"] <- legend_mod2
  }
  if (!is.null(dat)) {
    color_vals["observed"] <- "blue"
    color_labels["observed"] <- legend_obs
  }
  
  if (length(color_vals) > 0) {
    p <- p + ggplot2::scale_color_manual(values = color_vals, labels = color_labels)
  }
  
  return(p)
}