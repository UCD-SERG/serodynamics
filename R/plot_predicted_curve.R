#' @title Generate Predicted Antibody Response Curves
#' @author Kwan Ho Lee
#' @description
#' Uses median parameter estimates to plot predicted antibody response curves.
#'
#' @param param_medians_wide A tibble with median parameter estimates.
#' @return A ggplot object displaying predicted antibody response curves.
#' @export
#' @example inst/examples/examples-plot_predicted_curve.R

plot_predicted_curve <- function(param_medians_wide) {
  
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  
  tx2 <- seq(0, 1200, by = 5)  # Regularly spaced time points
  
  ab <- function(t, y0, y1, t1, alpha, shape) {
    beta <- log(y1 / y0) / t1
    yt <- ifelse(t <= t1, y0 * exp(beta * t),
                 (y1^(1 - shape) - (1 - shape) * alpha * (t - t1))^(1 / (1 - shape)))
    return(yt)
  }
  
  dT <- data.frame(t = tx2) %>%
    mutate(ID = row_number()) %>%
    pivot_wider(names_from = ID, values_from = t, names_prefix = "time") %>%
    slice(rep(1:n(), each = nrow(param_medians_wide)))
  
  serocourse_all <- cbind(param_medians_wide, dT) %>%
    pivot_longer(cols = starts_with("time"), values_to = "t") %>%
    select(-name) %>%
    rowwise() %>%
    mutate(res = ab(t, y0, y1, t1, alpha, shape)) %>%
    ungroup()
  
  plot1 <- ggplot() +
    aes(x = t, y = res, group = Subject, color = factor(Subject)) +
    facet_wrap(~ antigen_iso, ncol = 2) +
    geom_line(data = serocourse_all, alpha = 0.3) +  
    theme_minimal() +
    labs(x = "Days since fever onset", y = "ELISA units", color = "Subject") +
    theme(legend.position = "none")  
  
  return(plot1)
}
