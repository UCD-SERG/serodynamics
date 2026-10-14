#' Plot Prior, Population Posterior, and Posterior Predictive Densities
#'
#' @description
#' Compares the prior distribution for the population mean,
#' the population-level posterior, and the posterior predictive
#' distribution for a new individual.
#'
#' @param model An `sr_model` object returned by [run_mod()].
#'   The object must contain the `priors` and `population_params`
#'   attributes and posterior draws for `Subject == "newperson"`.
#' @param iso Optional character vector of antigen/isotypes.
#'   Defaults to all available antigen/isotypes.
#' @param param Optional character vector of parameters.
#'   Options are `"y0"`, `"y1"`, `"t1"`, `"shape"`, and `"alpha"`.
#' @param strat Optional character vector of stratification levels.
#' @param distributions Character vector selecting distributions:
#'   `"Prior"`, `"Population posterior"`, and
#'   `"Posterior predictive"`.
#' @param predictive_transform Named list of functions mapping
#'   subject-level predictive draws onto the population-mean
#'   parameter scale. Identity transformations are used for
#'   `y0`, `t1`, and `alpha` by default. Explicit transformations
#'   are required for `y1` and `shape`.
#' @param ncol Number of facet columns.
#' @param linewidth Width of density curves.
#'
#' @details
#' Priors are Normal distributions with mean `mu_hyp_param`
#' and precision `prec_hyp_param`. They describe uncertainty
#' in the population mean, not variation among individuals.
#'
#' Population posterior draws come from `mu.par`.
#' Predictive draws come from the modeled `"newperson"`.
#'
#' All distributions are displayed on the population-mean
#' parameter scale. Because some subject-level parameters
#' are transformed by the model, transformations must be
#' verified against the JAGS model before comparison.
#'
#' The function uses the exact Normal prior density, rather
#' than Monte Carlo samples from that prior.
#'
#' @return A `ggplot2` object with one panel per parameter,
#'   antigen/isotype, and stratification.
#'
#' @examples
#' \dontrun{
#' data(nepal_sees_jags_output, package = "serodynamics")
#'
#' plot_prior_posterior(
#'   nepal_sees_jags_output,
#'   param = "y0"
#' )
#' }
#'
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
    predictive_transform = list(
      y0 = identity,
      t1 = identity,
      alpha = identity
    ),
    ncol = 3,
    linewidth = 0.9
) {
  
  params <- c("y0", "y1", "t1", "shape", "alpha")
  allowed <- c(
    "Prior",
    "Population posterior",
    "Posterior predictive"
  )
  
  if (!all(distributions %in% allowed)) {
    stop("Unknown distribution requested.")
  }
  
  priors <- attr(model, "priors")
  pop <- attr(model, "population_params")
  
  if (is.null(priors)) {
    stop("Model does not contain prior attributes.")
  }
  
  if (is.null(pop)) {
    stop(
      "Population parameters are missing. ",
      "Fit with with_pop_params = TRUE."
    )
  }
  
  required <- c(
    "mu_hyp_param",
    "prec_hyp_param"
  )
  
  if (!all(required %in% names(priors))) {
    stop("Required prior hyperparameters are missing.")
  }
  
  mu <- as.numeric(priors$mu_hyp_param)
  precision <- as.numeric(priors$prec_hyp_param)
  
  if (length(mu) != 5 || length(precision) != 5 ||
      any(!is.finite(mu)) ||
      any(!is.finite(precision)) ||
      any(precision <= 0)) {
    stop("Invalid population-mean prior specifications.")
  }
  
  # Population posterior
  pop <- as.data.frame(pop)
  
  pop <- pop[
    pop$Population_Parameter == "mu.par",
    c(
      "Iso_type",
      "Parameter",
      "Stratification",
      "value"
    )
  ]
  
  # Normalize the model's shape parameter name.
  pop$Parameter[pop$Parameter == "r"] <- "shape"
  
  # Apply requested filters.
  if (!is.null(iso)) {
    pop <- pop[pop$Iso_type %in% iso, ]
  }
  
  if (!is.null(param)) {
    pop <- pop[pop$Parameter %in% param, ]
  }
  
  if (!is.null(strat)) {
    pop <- pop[pop$Stratification %in% strat, ]
  }
  
  pop <- pop[pop$Parameter %in% params, ]
  
  if (nrow(pop) == 0) {
    stop("No matching population posterior samples.")
  }
  
  keys <- unique(
    pop[c("Iso_type", "Parameter", "Stratification")]
  )
  
  # Validate transformations before constructing the plot.
  if ("Posterior predictive" %in% distributions) {
    missing_transforms <- setdiff(
      unique(keys$Parameter),
      names(predictive_transform)
    )
    
    if (length(missing_transforms) > 0) {
      stop(
        "Supply verified predictive_transform functions for: ",
        paste(missing_transforms, collapse = ", "),
        ". These parameters may use different scales."
      )
    }
  }
  
  # Build population posterior.
  pop$Distribution <- "Population posterior"
  
  # Build posterior predictive from newperson.
  pred <- as.data.frame(model)
  
  pred <- pred[
    pred$Subject == "newperson",
    c(
      "Iso_type",
      "Parameter",
      "Stratification",
      "value"
    )
  ]
  
  pred$Parameter[pred$Parameter == "r"] <- "shape"
  
  pred <- merge(
    pred,
    keys,
    by = c("Iso_type", "Parameter", "Stratification")
  )
  
  if ("Posterior predictive" %in% distributions &&
      nrow(pred) == 0) {
    stop(
      "No newperson draws found. ",
      "Fit the model with predictive sampling enabled."
    )
  }
  
  if (nrow(pred) > 0 &&
      "Posterior predictive" %in% distributions) {
    
    for (p in unique(pred$Parameter)) {
      idx <- pred$Parameter == p
      transform <- predictive_transform[[p]]
      
      if (!is.function(transform)) {
        stop("Transformation for ", p, " is not a function.")
      }
      
      pred$value[idx] <- transform(pred$value[idx])
    }
  }
  
  pred$Distribution <- "Posterior predictive"
  
  # Combine posterior draws.
  plot_data <- rbind(
    pop[pop$Distribution %in% distributions, ],
    pred[pred$Distribution %in% distributions, ]
  )
  
  plot_data <- plot_data[
    is.finite(plot_data$value),
  ]
  
  # Exact analytical prior densities.
  prior_data <- data.frame()
  
  if ("Prior" %in% distributions) {
    
    prior_list <- lapply(seq_len(nrow(keys)), function(i) {
      
      key <- keys[i, ]
      j <- match(key$Parameter, params)
      
      m <- mu[j]
      sd <- sqrt(1 / precision[j])
      
      # Include the prior range and observed posterior range.
      subset_values <- plot_data$value[
        plot_data$Iso_type == key$Iso_type &
          plot_data$Parameter == key$Parameter &
          plot_data$Stratification == key$Stratification
      ]
      
      limits <- c(m - 4 * sd, m + 4 * sd)
      
      if (length(subset_values) > 0) {
        limits <- range(
          c(limits, subset_values),
          finite = TRUE
        )
      }
      
      x <- seq(limits[1], limits[2], length.out = 512)
      
      data.frame(
        Iso_type = key$Iso_type,
        Parameter = key$Parameter,
        Stratification = key$Stratification,
        value = x,
        density = stats::dnorm(x, m, sd),
        Distribution = "Prior"
      )
    })
    
    prior_data <- do.call(rbind, prior_list)
  }
  
  # Facet label.
  plot_data$Facet <- paste(
    plot_data$Iso_type,
    plot_data$Stratification,
    plot_data$Parameter,
    sep = " | "
  )
  
  if (nrow(prior_data) > 0) {
    prior_data$Facet <- paste(
      prior_data$Iso_type,
      prior_data$Stratification,
      prior_data$Parameter,
      sep = " | "
    )
  }
  
  # Plot.
  p <- ggplot2::ggplot()
  
  if (nrow(prior_data) > 0) {
    p <- p +
      ggplot2::geom_line(
        data = prior_data,
        ggplot2::aes(
          x = value,
          y = density,
          color = Distribution,
          linetype = Distribution
        ),
        linewidth = linewidth
      )
  }
  
  if (nrow(plot_data) > 0) {
    p <- p +
      ggplot2::geom_density(
        data = plot_data,
        ggplot2::aes(
          x = value,
          color = Distribution,
          linetype = Distribution
        ),
        linewidth = linewidth,
        na.rm = TRUE
      )
  }
  
  p +
    ggplot2::facet_wrap(
      ~ Facet,
      ncol = ncol,
      scales = "free"
    ) +
    ggplot2::scale_color_manual(
      values = c(
        "Prior" = "grey40",
        "Population posterior" = "dodgerblue3",
        "Posterior predictive" = "gold3"
      ),
      breaks = distributions
    ) +
    ggplot2::scale_linetype_manual(
      values = c(
        "Prior" = "dashed",
        "Population posterior" = "solid",
        "Posterior predictive" = "solid"
      ),
      breaks = distributions
    ) +
    ggplot2::labs(
      x = "Parameter value (population-mean scale)",
      y = "Density",
      color = NULL,
      linetype = NULL
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.position = "top",
      panel.grid.minor = ggplot2::element_blank(),
      strip.background = ggplot2::element_rect(
        fill = "grey95"
      )
    )
}
