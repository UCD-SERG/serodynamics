#' @title Generate Predicted Antibody Response Curves
#' @author Kwan Ho Lee
#' @description
#' Uses median parameter estimates to plot predicted antibody response curves.
#' If observed data is provided, it overlays the observed values as points and
#' connects them with lines.
#'
#' @param param_medians_wide A tibble with median parameter estimates.
#' @param dat (Optional) A tibble with observed antibody response data. 
#' It must contain `dayssincefeveronset`, `result`, `id`, and `antigen_iso`.
#' @return A ggplot object displaying predicted antibody response curves with optional observed data.
#' @export
#' @example inst/examples/examples-plot_predicted_curve.R

plot_predicted_curve <- function(param_medians_wide, dat = NULL) {
  
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  
  # Define the time sequence for prediction
  tx2 <- seq(0, 1200, by = 5)  
  
  # Antibody response model function
  ab <- function(t, y0, y1, t1, alpha, shape) {
    beta <- log(y1 / y0) / t1
    yt <- ifelse(t <= t1, y0 * exp(beta * t),
                 (y1^(1 - shape) - (1 - shape) * alpha * (t - t1))^(1 / (1 - shape)))
    return(yt)
  }
  
  # Generate predicted time points
  dT <- data.frame(t = tx2) %>%
    mutate(ID = row_number()) %>%
    pivot_wider(names_from = ID, values_from = t, names_prefix = "time") %>%
    slice(rep(1:n(), each = nrow(param_medians_wide)))
  
  # Compute predicted antibody response curves
  serocourse_all <- cbind(param_medians_wide, dT) %>%
    pivot_longer(cols = starts_with("time"), values_to = "t") %>%
    select(-name) %>%
    rowwise() %>%
    mutate(res = ab(t, y0, y1, t1, alpha, shape)) %>%
    ungroup()
  
  # Ensure predicted data has an 'id' column (if missing, create one)
  serocourse_all <- serocourse_all %>%
    mutate(id = as.factor(Subject))  # Adjust 'Subject' if different in dataset
  
  # Initialize plot with predicted antibody response curve
  plot1 <- ggplot() +
    geom_line(data = serocourse_all, aes(x = t, y = res, group = id), color = "red", alpha = 0.3) +
    theme_minimal() +
    labs(x = "Days since fever onset", y = "ELISA units") +
    theme(legend.position = "none")
  
  # Overlay observed data if provided
  if (!is.null(dat)) {
    observed_data <- dat %>%
      rename(t = dayssincefeveronset, res = result) %>%
      select(id, t, res, antigen_iso) %>%
      mutate(id = as.factor(id))  # Ensure 'id' is a factor for grouping
    
    plot1 <- plot1 +
      geom_point(data = observed_data, aes(x = t, y = res, group = id), color = "blue", size = 2) +
      geom_line(data = observed_data, aes(x = t, y = res, group = id), color = "blue", linewidth = 1)
  }
  
  return(plot1)
}
