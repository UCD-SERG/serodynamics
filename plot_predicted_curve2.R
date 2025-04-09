#' @title Generate Predicted Antibody Response Curves (with Optional Predictive Interval)
#' @author Kwan Ho Lee
#' @description
#' Generates predicted antibody response curves using median parameter estimates.
#' If observed data is provided, it overlays the observed values as points and
#' connects them with lines. Optionally, if \code{show_interval = TRUE} and
#' the input tibbles contain lower/upper parameter estimates, it draws a
#' semi-transparent ribbon indicating the 2.5th--97.5th percentile predictive interval.
#'
#' @importFrom stringr str_extract
#'
#' @param param_medians_wide A tibble with median parameter estimates (e.g., from
#'   \code{process_jags_output()}). Must contain columns \code{y0, y1, t1, alpha, shape}.
#'   If \code{show_interval = TRUE}, it should also contain columns
#'   \code{y0_lower, y1_lower, t1_lower, alpha_lower, shape_lower} and
#'   \code{y0_upper, y1_upper, t1_upper, alpha_upper, shape_upper}.
#' @param param_medians_wide2 (Optional) A second tibble with median parameter estimates,
#'   for plotting a second model. If it contains a column \code{dayssincefeveronset},
#'   it is treated as observed data (and \code{dat} is ignored).
#' @param dat (Optional) A tibble with observed antibody response data.
#'   It must contain \code{dayssincefeveronset}, \code{result}, \code{id}, and \code{antigen_iso}.
#' @param legend_obs A character string for the observed data legend label (default: "Observed Data").
#' @param legend_mod1 A character string for the first model's legend label (default: "").
#'   If empty, no legend key is shown for the first model.
#' @param legend_mod2 A character string for the second model's legend label (default: "").
#'   If empty, no legend key is shown for the second model.
#' @param show_interval Logical (default \code{FALSE}). If \code{TRUE}, the function
#'   attempts to compute lower and upper predicted curves using the \code{_lower} and
#'   \code{_upper} parameter columns. A shaded ribbon is drawn between them, illustrating
#'   the 2.5th--97.5th percentile predictive interval.
#'
#' @return A \code{ggplot} object displaying predicted antibody response curves.
#' If two parameter sets are provided, the first is plotted in red and the second in green.
#' Observed data (if provided) are shown in blue. If \code{show_interval = TRUE}, a
#' semi-transparent ribbon around the median curve shows the predictive interval.
#' 
#' @export
#' 
#' @examples
#' \dontrun{
#' # Example (pseudo-code) using pre-saved JAGS results:
#' param_medians_wide_128 <- readRDS("param_medians_wide_128.rds")
#' 
#' # Generate predicted antibody response curve with no predictive interval
#' plot_pred_only <- plot_predicted_curve2(param_medians_wide_128, show_interval = FALSE)
#' print(plot_pred_only)
#' 
#' # If param_medians_wide_128 also contains y0_lower, y0_upper, etc.,
#' # you can enable the predictive interval:
#' plot_pred_interval <- plot_predicted_curve2(param_medians_wide_128, show_interval = TRUE)
#' print(plot_pred_interval)
#' }
plot_predicted_curve2 <- function(param_medians_wide, param_medians_wide2 = NULL, dat = NULL,
                                  legend_obs = "Observed Data",
                                  legend_mod1 = "",
                                  legend_mod2 = "",
                                  show_interval = FALSE) {
  
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
    ifelse(t <= t1, 
           y0 * exp(beta * t),
           (y1^(1 - shape) - (1 - shape) * alpha * (t - t1))^(1 / (1 - shape)))
  }
  
  # ─────────────────────────────────────────────────────────────────────────────
  # Compute predicted curves (median) for the first set (mod1)
  # ─────────────────────────────────────────────────────────────────────────────
  dT1 <- data.frame(t = tx2) %>%
    dplyr::mutate(ID = dplyr::row_number()) %>%
    tidyr::pivot_wider(names_from = ID, values_from = t, names_prefix = "time") %>%
    dplyr::slice(rep(1:nrow(.), each = nrow(param_medians_wide)))
  
  serocourse_all1 <- cbind(param_medians_wide, dT1) %>%
    tidyr::pivot_longer(cols = dplyr::starts_with("time"), values_to = "t") %>%
    dplyr::select(-name) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(res_median = ab(t, y0, y1, t1, alpha, shape)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(id = as.factor(Subject))
  
  # If show_interval is TRUE, compute the predictive interval curves (lower/upper) for mod1.
  serocourse_all1_ribbon <- NULL
  if (show_interval) {
    # Check for the needed columns
    if (all(c("y0_lower", "y1_lower", "t1_lower", "alpha_lower", "shape_lower") %in% colnames(param_medians_wide)) &&
        all(c("y0_upper", "y1_upper", "t1_upper", "alpha_upper", "shape_upper") %in% colnames(param_medians_wide))) {
      
      # Lower curve
      serocourse_all1_lower <- cbind(param_medians_wide, dT1) %>%
        tidyr::pivot_longer(cols = dplyr::starts_with("time"), values_to = "t") %>%
        dplyr::select(-name) %>%
        dplyr::rowwise() %>%
        dplyr::mutate(res_lower = ab(t, y0_lower, y1_lower, t1_lower, alpha_lower, shape_lower)) %>%
        dplyr::ungroup() %>%
        dplyr::mutate(id = as.factor(Subject)) %>%
        dplyr::select(id, t, res_lower)
      
      # Upper curve
      serocourse_all1_upper <- cbind(param_medians_wide, dT1) %>%
        tidyr::pivot_longer(cols = dplyr::starts_with("time"), values_to = "t") %>%
        dplyr::select(-name) %>%
        dplyr::rowwise() %>%
        dplyr::mutate(res_upper = ab(t, y0_upper, y1_upper, t1_upper, alpha_upper, shape_upper)) %>%
        dplyr::ungroup() %>%
        dplyr::mutate(id = as.factor(Subject)) %>%
        dplyr::select(id, t, res_upper)
      
      # Merge median, lower, upper into one data frame for easy ribbon plotting
      serocourse_all1_ribbon <- serocourse_all1 %>%
        dplyr::select(id, t, res_median) %>%
        dplyr::left_join(serocourse_all1_lower, by = c("id", "t")) %>%
        dplyr::left_join(serocourse_all1_upper, by = c("id", "t"))
      
    } else {
      warning("Predictive interval columns not found in param_medians_wide; skipping interval plotting for mod1.")
      show_interval <- FALSE
    }
  }
  
  # ─────────────────────────────────────────────────────────────────────────────
  # Compute predicted curves (median) for the second set (mod2), if provided
  # ─────────────────────────────────────────────────────────────────────────────
  serocourse_all2 <- NULL
  serocourse_all2_ribbon <- NULL
  if (!is.null(param_medians_wide2)) {
    dT2 <- data.frame(t = tx2) %>%
      dplyr::mutate(ID = dplyr::row_number()) %>%
      tidyr::pivot_wider(names_from = ID, values_from = t, names_prefix = "time") %>%
      dplyr::slice(rep(1:nrow(.), each = nrow(param_medians_wide2)))
    
    serocourse_all2 <- cbind(param_medians_wide2, dT2) %>%
      tidyr::pivot_longer(cols = dplyr::starts_with("time"), values_to = "t") %>%
      dplyr::select(-name) %>%
      dplyr::rowwise() %>%
      dplyr::mutate(res_median = ab(t, y0, y1, t1, alpha, shape)) %>%
      dplyr::ungroup() %>%
      dplyr::mutate(id = as.factor(Subject))
    
    if (show_interval) {
      if (all(c("y0_lower", "y1_lower", "t1_lower", "alpha_lower", "shape_lower") %in% colnames(param_medians_wide2)) &&
          all(c("y0_upper", "y1_upper", "t1_upper", "alpha_upper", "shape_upper") %in% colnames(param_medians_wide2))) {
        
        serocourse_all2_lower <- cbind(param_medians_wide2, dT2) %>%
          tidyr::pivot_longer(cols = dplyr::starts_with("time"), values_to = "t") %>%
          dplyr::select(-name) %>%
          dplyr::rowwise() %>%
          dplyr::mutate(res_lower = ab(t, y0_lower, y1_lower, t1_lower, alpha_lower, shape_lower)) %>%
          dplyr::ungroup() %>%
          dplyr::mutate(id = as.factor(Subject)) %>%
          dplyr::select(id, t, res_lower)
        
        serocourse_all2_upper <- cbind(param_medians_wide2, dT2) %>%
          tidyr::pivot_longer(cols = dplyr::starts_with("time"), values_to = "t") %>%
          dplyr::select(-name) %>%
          dplyr::rowwise() %>%
          dplyr::mutate(res_upper = ab(t, y0_upper, y1_upper, t1_upper, alpha_upper, shape_upper)) %>%
          dplyr::ungroup() %>%
          dplyr::mutate(id = as.factor(Subject)) %>%
          dplyr::select(id, t, res_upper)
        
        serocourse_all2_ribbon <- serocourse_all2 %>%
          dplyr::select(id, t, res_median) %>%
          dplyr::left_join(serocourse_all2_lower, by = c("id", "t")) %>%
          dplyr::left_join(serocourse_all2_upper, by = c("id", "t"))
      } else {
        warning("Predictive interval columns not found in param_medians_wide2; skipping interval plotting for mod2.")
      }
    }
  }
  
  # ─────────────────────────────────────────────────────────────────────────────
  # Initialize the base plot
  # ─────────────────────────────────────────────────────────────────────────────
  p <- ggplot2::ggplot() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Days since fever onset", y = "ELISA units", color = "Data Type") +
    ggplot2::theme(legend.position = "right")
  
  # ─────────────────────────────────────────────────────────────────────────────
  # Plot mod1 median curve + optional ribbon
  # ─────────────────────────────────────────────────────────────────────────────
  if (!is.null(serocourse_all1)) {
    if (legend_mod1 != "") {
      p <- p + ggplot2::geom_line(
        data = serocourse_all1,
        ggplot2::aes(x = t, y = res_median, group = id, color = "mod1"),
        alpha = 0.3,
        show.legend = TRUE
      )
    } else {
      p <- p + ggplot2::geom_line(
        data = serocourse_all1,
        ggplot2::aes(x = t, y = res_median, group = id),
        color = "red",
        alpha = 0.3,
        show.legend = FALSE
      )
    }
    
    if (show_interval && !is.null(serocourse_all1_ribbon)) {
      p <- p +
        ggplot2::geom_ribbon(
          data = serocourse_all1_ribbon,
          ggplot2::aes(x = t, ymin = res_lower, ymax = res_upper, group = id),
          fill = "red",
          alpha = 0.2,
          inherit.aes = FALSE
        ) +
        ggplot2::geom_line(
          data = serocourse_all1_ribbon,
          ggplot2::aes(x = t, y = res_median, group = id),
          color = "red",
          size = 1
        )
    }
  }
  
  # ─────────────────────────────────────────────────────────────────────────────
  # Plot mod2 median curve + optional ribbon
  # ─────────────────────────────────────────────────────────────────────────────
  if (!is.null(serocourse_all2)) {
    if (legend_mod2 != "") {
      p <- p + ggplot2::geom_line(
        data = serocourse_all2,
        ggplot2::aes(x = t, y = res_median, group = id, color = "mod2"),
        alpha = 0.3,
        show.legend = TRUE
      )
    } else {
      p <- p + ggplot2::geom_line(
        data = serocourse_all2,
        ggplot2::aes(x = t, y = res_median, group = id),
        color = "green",
        alpha = 0.3,
        show.legend = FALSE
      )
    }
    
    if (show_interval && !is.null(serocourse_all2_ribbon)) {
      p <- p +
        ggplot2::geom_ribbon(
          data = serocourse_all2_ribbon,
          ggplot2::aes(x = t, ymin = res_lower, ymax = res_upper, group = id),
          fill = "green",
          alpha = 0.2,
          inherit.aes = FALSE
        ) +
        ggplot2::geom_line(
          data = serocourse_all2_ribbon,
          aes(x = t, y = res_median, group = id),
          color = "green",
          size = 1
        )
    }
  }
  
  # ─────────────────────────────────────────────────────────────────────────────
  # Overlay observed data if provided
  # ─────────────────────────────────────────────────────────────────────────────
  if (!is.null(dat)) {
    observed_data <- dat %>%
      dplyr::rename(t = dayssincefeveronset, res = result) %>%
      dplyr::select(id, t, res, antigen_iso) %>%
      dplyr::mutate(id = as.factor(id))
    
    p <- p +
      ggplot2::geom_point(
        data = observed_data,
        ggplot2::aes(x = t, y = res, group = id, color = "observed"),
        size = 2,
        show.legend = TRUE
      ) +
      ggplot2::geom_line(
        data = observed_data,
        aes(x = t, y = res, group = id, color = "observed"),
        linewidth = 1,
        show.legend = TRUE
      )
  }
  
  # ─────────────────────────────────────────────────────────────────────────────
  # Construct the color scale manually
  # ─────────────────────────────────────────────────────────────────────────────
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
