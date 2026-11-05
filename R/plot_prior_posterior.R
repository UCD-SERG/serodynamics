#' Compare Prior and Posterior Predictive Parameter Distributions
#'
#' @param model Fitted sr_model object.
#' @param iso Optional antigen/isotype selection.
#' @param param Optional parameter selection.
#' @param strat Optional stratification selection.
#' @param n_prior Number of prior predictive draws.
#' @param ncol Number of facet columns.
#' @param log_x Use log10 x-axis.
#' @param facet_scales Facet scale behavior.
#'
#' @return A ggplot object with simulation data attached.
#' @export
plot_prior_posterior <- function(
    model,
    iso = NULL,
    param = NULL,
    strat = NULL,
    n_prior = 10000,
    ncol = 3,
    log_x = FALSE,
    facet_scales = "free"
) {
  
  params <- c("y0", "y1", "t1", "alpha", "shape")
  
  # Extract original prior specification
  priors <- attr(model, "priors")
  
  if (is.null(priors)) {
    stop("Model does not contain prior attributes.")
  }
  
  # Prepare priors using same function as model fitting
  pr <- prep_priors(
    max_antigens = 1,
    mu_hyp_param = priors$mu_hyp_param,
    prec_hyp_param = priors$prec_hyp_param,
    omega_param = priors$omega_param,
    wishdf_param = priors$wishdf_param,
    prec_logy_hyp_param = priors$prec_logy_hyp_param
  )
  
  # Simulate individual-level prior predictive parameters
  prior_draws <- draw_prior_predictive(
    pr = pr,
    n = n_prior,
  )
  
  prior_long <- prior_draws |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(params),
      names_to = "Parameter",
      values_to = "value"
    ) |>
    dplyr::mutate(
      Distribution = "Prior predictive"
    )
  
  # Extract individual-level posterior predictive samples
  posterior_long <- as.data.frame(model) |>
    dplyr::filter(
      Subject == "newperson",
      Parameter %in% params
    ) |>
    dplyr::mutate(
      value = as.numeric(as.character(value)),
      Distribution = "Posterior predictive"
    ) |>
    dplyr::select(
      Iso_type,
      Stratification,
      Parameter,
      value,
      Distribution
    )
  
  # Optional selection
  if (!is.null(iso)) {
    posterior_long <- posterior_long |>
      dplyr::filter(Iso_type %in% iso)
  }
  
  if (!is.null(param)) {
    posterior_long <- posterior_long |>
      dplyr::filter(Parameter %in% param)
    
    prior_long <- prior_long |>
      dplyr::filter(Parameter %in% param)
  }
  
  if (!is.null(strat)) {
    posterior_long <- posterior_long |>
      dplyr::filter(Stratification %in% strat)
  }
  
  if (nrow(posterior_long) == 0) {
    stop("No posterior predictive draws match the selection.")
  }
  
  # Repeat prior for relevant antigen/stratification groups
  groups <- posterior_long |>
    dplyr::distinct(Iso_type, Stratification)
  
  prior_long <- tidyr::crossing(
    groups,
    prior_long
  )
  
  # Combine
  plot_data <- dplyr::bind_rows(
    prior_long,
    posterior_long
  ) |>
    dplyr::mutate(
      Distribution = factor(
        Distribution,
        levels = c(
          "Prior predictive",
          "Posterior predictive"
        )
      ),
      Parameter = factor(
        Parameter,
        levels = params
      )
    )
  
  # Record non-finite draws before filtering
  invalid_n <- sum(!is.finite(plot_data$value))
  
  if (invalid_n > 0) {
    warning(
      invalid_n,
      " non-finite predictive values excluded from density estimation."
    )
  }
  
  plot_data <- plot_data |>
    dplyr::filter(is.finite(value))
  
  if (log_x) {
    plot_data <- plot_data |>
      dplyr::filter(value > 0)
  }
  
  # Plot
  p <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = value,
      color = Distribution,
      fill = Distribution,
      linetype = Distribution
    )
  ) +
    ggplot2::geom_density(
      alpha = 0.25,
      linewidth = 0.7,
      na.rm = TRUE
    ) +
    ggh4x::facet_grid2(
      rows = vars(Iso_type, Stratification),
      cols = vars(Parameter),
      scales = "free",
      independent = "all",
      switch = "none"
    ) +
    ggplot2::scale_color_manual(
      values = c(
        "Prior predictive" = "grey40",
        "Posterior predictive" = "dodgerblue3"
      )
    ) +
    ggplot2::scale_fill_manual(
      values = c(
        "Prior predictive" = "grey70",
        "Posterior predictive" = "dodgerblue3"
      )
    ) +
    ggplot2::scale_linetype_manual(
      values = c(
        "Prior predictive" = "dashed",
        "Posterior predictive" = "solid"
      )
    ) +
    ggplot2::labs(
      x = "Parameter value",
      y = "Density",
      color = NULL,
      fill = NULL,
      linetype = NULL,
      title = "Prior vs. posterior predictive distributions"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.position = "top",
      panel.grid.minor = ggplot2::element_blank(),
      strip.background = ggplot2::element_rect(
        fill = "grey95"
      )
    )
  
  if (log_x) {
    p <- p +
      ggplot2::scale_x_log10()
  }
  
  # Retain draws for diagnostics
  attr(p, "predictive_data") <- plot_data
  
  return(p)
}


  