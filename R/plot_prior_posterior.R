#' Plot Prior, Population Posterior, and Posterior Predictive Densities
#'
#' @description
#' Overlays prior, population-level posterior, and posterior
#' predictive distributions for serodynamics model parameters.
#' All distributions are shown on the original parameter scale.
#'
#' @param model An sr_model object returned by run_mod().
#' @param iso Optional antigen/isotype selection.
#' @param param Optional parameter selection.
#' @param strat Optional stratification selection.
#' @param distributions Distributions to include.
#' @param n_prior Number of prior Monte Carlo draws.
#' @param ncol Number of facet columns.
#'
#' @details
#' Population parameters use the transformations:
#'
#' log(y0), log(y1 - y0), log(t1),
#' log(alpha), and log(shape - 1).
#'
#' The corresponding original-scale parameters are:
#'
#' y0 = exp(mu1)
#' y1 = exp(mu1) + exp(mu2)
#' t1 = exp(mu3)
#' alpha = exp(mu4)
#' shape = 1 + exp(mu5)
#'
#' Prior population means are sampled independently from
#' Normal(mu_hyp_param, 1 / prec_hyp_param).
#'
#' @return A ggplot object.
#' @export
plot_prior_posterior <- function(
    model,
    iso = NULL,
    param = NULL,
    strat = NULL,
    distributions = c(
      "Prior",
      "Population posterior",
      "Posterior predictive"
    ),
    n_prior = 10000,
    ncol = 3,
    trim_quantiles = c(0.01, 0.99), 
    log_x = FALSE
) {
  
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  
  params <- c("y0", "y1", "t1", "alpha", "shape")
  
  transformed <- c(
    "log(y0)",
    "log(y1 - y0)",
    "log(t1)",
    "log(alpha)",
    "log(shape - 1)"
  )
  
  # Extract model attributes
  priors <- attr(model, "priors")
  pop <- attr(model, "population_params")
  
  if (is.null(priors) || is.null(pop)) {
    stop("Model must contain priors and population_params.")
  }
  
  # Identify posterior draw column.
  # This must preserve joint draw alignment.
  pop <- as.data.frame(pop)
  
  if (!"Iteration" %in% names(pop)) {
    stop(
      "Population posterior must contain an Iteration ",
      "column to preserve joint posterior draws."
    )
  }
  
  # Population mean parameters
  pop <- as.data.frame(pop) %>%
    filter(Population_Parameter == "mu.par", Parameter %in% transformed) %>%
    mutate(value = as.numeric(as.character(value)))
  
  # Assign a draw ID within each parameter and group
  pop <- pop %>%
    group_by(Iso_type, Stratification, Parameter) %>%
    mutate(draw_id = row_number()) %>%
    ungroup()
  
  
  # Convert to wide format
  pop_wide <- pop %>%
    select(Iso_type, Stratification, draw_id, Parameter, value) %>%
    pivot_wider(
      id_cols = c(Iso_type, Stratification, draw_id),
      names_from = Parameter,
      values_from = value
    )
  
  
  pop_original <- pop_wide %>%
    transmute(
      Iso_type,
      Stratification,
      draw_id,
      y0 = exp(.data[["log(y0)"]]),
      y1 = exp(.data[["log(y0)"]]) +
        exp(.data[["log(y1 - y0)"]]),
      t1 = exp(.data[["log(t1)"]]),
      alpha = exp(.data[["log(alpha)"]]),
      shape = 1 + exp(.data[["log(shape - 1)"]])
    ) %>%
    pivot_longer(
      cols = c(y0, y1, t1, alpha, shape),
      names_to = "Parameter",
      values_to = "value"
    ) %>%
    mutate(
      Distribution = "Population posterior"
    )
  
  prior_mu <- priors$mu_hyp_param
  prior_precision <- priors$prec_hyp_param
  
  if (length(prior_mu) != 5 ||
      length(prior_precision) != 5 ||
      any(prior_precision <= 0)) {
    stop("Invalid prior hyperparameters.")
  }
  
  prior_draws <- sapply(seq_along(params), function(j) {
    rnorm(
      n_prior,
      mean = prior_mu[j],
      sd = sqrt(1 / prior_precision[j])
    )
  })
  
  colnames(prior_draws) <- transformed
  
  # Transform priors to original parameter scale
  prior_original <- tibble(
    y0 = exp(prior_draws[, 1]),
    y1 = exp(prior_draws[, 1]) + exp(prior_draws[, 2]),
    t1 = exp(prior_draws[, 3]),
    alpha = exp(prior_draws[, 4]),
    shape = 1 + exp(prior_draws[, 5])
  ) %>%
    pivot_longer(
      everything(),
      names_to = "Parameter",
      values_to = "value"
    )
  
  # Replicate prior for each antigen/isotype and stratum
  groups <- pop_original %>%
    distinct(Iso_type, Stratification)
  
  prior_original <- crossing(
    groups,
    prior_original
  ) %>%
    mutate(Distribution = "Prior")
  
  # Posterior predictive samples
  predictive <- as.data.frame(model) %>%
    filter(Subject == "newperson") %>%
    mutate(
      Parameter = as.character(Parameter),
      Distribution = "Posterior predictive"
    ) %>%
    filter(Parameter %in% params) %>%
    select(
      Iso_type,
      Stratification,
      Parameter,
      value,
      Distribution
    )
  
  # Combine all distributions
  plot_data <- bind_rows(
    prior_original,
    pop_original %>%
      select(
        Iso_type,
        Stratification,
        Parameter,
        value,
        Distribution
      ),
    predictive
  )
  
  # Optional filtering
  if (!is.null(iso)) {
    plot_data <- plot_data %>%
      filter(Iso_type %in% iso)
  }
  
  if (!is.null(param)) {
    plot_data <- plot_data %>%
      filter(Parameter %in% param)
  }
  
  if (!is.null(strat)) {
    plot_data <- plot_data %>%
      filter(Stratification %in% strat)
  }
  
  plot_data <- plot_data %>%
    filter(
      Distribution %in% distributions,
      is.finite(value)
    ) %>%
    mutate(
      Distribution = factor(
        Distribution,
        levels = c(
          "Prior",
          "Population posterior",
          "Posterior predictive"
        )
      ),
      Parameter = factor(Parameter, levels = params)
    )
  
  if (log_x) {
    plot_data <- plot_data %>%
      filter(value > 0)
  }
  
  # Calculate quantiles for each distribution and facet
  facet_limits <- plot_data %>%
    group_by(
      Iso_type,
      Stratification,
      Parameter,
      Distribution
    ) %>%
    summarise(
      xmin = quantile(value, trim_quantiles[1], na.rm = TRUE),
      xmax = quantile(value, trim_quantiles[2], na.rm = TRUE),
      .groups = "drop"
    ) %>%
    group_by(Iso_type, Stratification, Parameter) %>%
    summarise(
      xmin = min(xmin),
      xmax = max(xmax),
      .groups = "drop"
    )
  
  # Adding limits to plot_data
  plot_data <- plot_data %>%
    left_join(
      facet_limits,
      by = c("Iso_type", "Stratification", "Parameter")
    ) %>%
    filter(
      value >= xmin,
      value <= xmax
    )
  
  # Create plot
  p <- ggplot(
    plot_data,
    aes(
      x = value,
      color = Distribution,
      fill = Distribution, 
      linetype = Distribution
    )
  ) +
    geom_density(
      linewidth = 0.5,
      na.rm = TRUE,
      alpha = 0.6
    ) +
    facet_grid(
      Iso_type + Stratification ~ Parameter,
      scales = "free"
    ) +
    scale_color_manual(
      values = c(
        "Prior" = "grey40",
        "Population posterior" = "dodgerblue3",
        "Posterior predictive" = "gold3"
      ),
      drop = TRUE
    ) +
    scale_fill_manual(
      values = c(
        "Prior" = "grey90",
        "Population posterior" = "dodgerblue3",
        "Posterior predictive" = "gold3"
      ),
      drop = TRUE
    ) +
    scale_linetype_manual(
      values = c(
        "Prior" = "dashed",
        "Population posterior" = "solid",
        "Posterior predictive" = "solid"
      ),
      drop = TRUE
    ) +
    labs(
      x = "Parameter value",
      y = "Density",
      color = NULL,
      linetype = NULL
    ) +
    theme_bw() +
    theme(
      legend.position = "top",
      panel.grid.minor = element_blank(),
      strip.background = element_rect(fill = "grey95")
    )
  
  # Optional log-scaled x-axis
  if (log_x) {
    p <- p +
      scale_x_log10(
        labels = scales::label_number()
      )
  }
  
  return(p)
}
  