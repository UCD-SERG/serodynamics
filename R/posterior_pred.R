
#' @title Posterior predictive check
#' @description
#' Generate posterior predictive antibody measurements using
#' individual-level posterior parameters and the population-level
#' observation precision.
#'
#' @param data Long-format posterior draws containing Subject,
#'   Iso_type, Stratification, Iteration, Chain, Parameter, and value.
#'   Parameters must be on the natural scale.
#' @param iso Specify antigen/isotype to include in posterior predictive check.
#' @param strat Specify stratification to be included in posterior predictive
#' check.
#' @param raw_dat Observed antibody data containing Subject,
#'   Iso_type, Stratification, t, and result after `use_att_names()`.
#' @param by_antigen Whether to facet by Iso_type.
#' @param n_sim Number of posterior predictive simulations.
#' @param ... Additional arguments (currently unused).
#'
#' @return A ggplot object showing observed and simulated densities.
#' @export
posterior_pred <- function(data,
                           raw_dat,
                           iso = NULL,
                           strat = NULL,
                           by_antigen = FALSE,
                           n_sim = 4,
                           ...) {
  
  # ----------------------------------------
  # 1. Extract observation precision
  # ----------------------------------------
  
  pop_params <- attr(data, "population_params")
  
  if (is.null(pop_params)) {
    stop("Missing population_params attribute.")
  }
  
  mod_prec_logy <- pop_params %>%
    filter(.data$Population_Parameter == "prec.logy") %>%
    transmute(
      Iteration,
      Chain,
      Iso_type,
      Stratification,
      prec_logy = value
    )
  
  # ----------------------------------------
  # 2. Prepare individual posterior parameters
  # ----------------------------------------
  
  mod_dat <- data %>%
    filter(Parameter %in% c(
      "alpha", "shape", "t1", "y0", "y1"
    )) %>%
    select(
      Subject, Iso_type, Stratification,
      Iteration, Chain, Parameter, value
    ) %>%
    pivot_wider(
      names_from = Parameter,
      values_from = value
    ) %>%
    filter(Subject != "newperson")
  
  # ----------------------------------------
  # 3. Prepare observed data
  # ----------------------------------------
  
  obs_dat <- raw_dat %>%
    use_att_names()
  strat_col <- attr(data, "strat")
  if (!is.null(strat_col) &&
      strat_col %in% names(obs_dat)) {
    obs_dat <- obs_dat %>%
      rename(Stratification = all_of(strat_col))
  } else if (!"Stratification" %in% names(obs_dat)) {
    obs_dat$Stratification <- "All"
  }
  obs_dat <- obs_dat %>%
    select(Subject, Iso_type, Stratification, t, result) %>%
    filter(!is.na(t), !is.na(result))
  
  # ----------------------------------------
  # 3b. Filter selected antigen/isotype and strata
  # ----------------------------------------
  
  if (!is.null(iso)) {
    
    mod_dat <- mod_dat %>%
      filter(Iso_type %in% iso)
    
    mod_prec_logy <- mod_prec_logy %>%
      filter(Iso_type %in% iso)
    
    obs_dat <- obs_dat %>%
      filter(Iso_type %in% iso)
  }
  
  if (!is.null(strat)) {
    
    mod_dat <- mod_dat %>%
      filter(Stratification %in% strat)
    
    mod_prec_logy <- mod_prec_logy %>%
      filter(Stratification %in% strat)
    
    obs_dat <- obs_dat %>%
      filter(Stratification %in% strat)
  }
  
  # Check that the selected groups contain observations
  if (nrow(obs_dat) == 0) {
    stop("No observed data match the selected ",
      "antigen/isotype or stratification.")
  }
  
  if (nrow(mod_dat) == 0 ||
      nrow(mod_prec_logy) == 0) {
    stop("No posterior draws match the selected ",
      "antigen/isotype or stratification.")
  }
  
  # ----------------------------------------
  # 4. Identify available posterior draws
  # ----------------------------------------
  
  available_draws <- mod_dat %>%
    distinct(Iteration, Chain) %>%
    inner_join(
      mod_prec_logy %>%
        distinct(Iteration, Chain),
      by = c("Iteration", "Chain")
    )
  
  if (nrow(available_draws) == 0) {
    stop("No matching posterior draws found.")
  }
  
  # ----------------------------------------
  # 5. Simulate posterior predictive datasets
  # ----------------------------------------
  
  simulated_list <- vector("list", n_sim)
  
  for (j in seq_len(n_sim)) {
    
    # Sample ONE joint posterior draw
    selected_draw <- available_draws %>%
      slice_sample(n = 1)
    
    iter_j <- selected_draw$Iteration
    chain_j <- selected_draw$Chain
    
    # Individual parameters for selected draw
    person_j <- mod_dat %>%
      filter(
        Iteration == iter_j,
        Chain == chain_j
      )
    
    # Observation precision for selected draw
    precision_j <- mod_prec_logy %>%
      filter(
        Iteration == iter_j,
        Chain == chain_j
      ) %>%
      select(Iso_type, Stratification, prec_logy)
    
    # Match individual parameters to observations
    pred_dat <- obs_dat |>
      filter(Subject %in% unique(person_j$Subject)) |>
      left_join(
        person_j,
        by = c(
          "Subject",
          "Iso_type",
          "Stratification"
        )
      ) |>
      left_join(
        precision_j,
        by = c(
          "Iso_type",
          "Stratification"
        )
      )
    
    # Check for missing parameters
    required <- c(
      "alpha", "shape", "t1", "y0",
      "y1", "prec_logy"
    )
    
    if (anyNA(pred_dat[, required])) {
      stop(
        "Missing individual parameters or precision ",
        "after joining posterior draws."
      )
    }
    
    # Expected serodynamic response
    pred_dat <- pred_dat %>%
      mutate(mu_hat = ab(t, y0, y1, t1, alpha, shape))
    
    if (any(!is.finite(pred_dat$mu_hat) |
            pred_dat$mu_hat <= 0)) {
      stop("Nonpositive or invalid predicted antibody values.")
    }
    
    if (any(!is.finite(pred_dat$prec_logy) |
            pred_dat$prec_logy <= 0)) {
      stop("Observation precision must be positive.")
    }
    
    # Simulate measurement error on log scale
    pred_dat <- pred_dat %>%
      mutate(
        sd_logy = 1 / sqrt(prec_logy),
        value = rlnorm(
          n = n(),
          meanlog = log(mu_hat),
          sdlog = sd_logy
        ),
        estimate = "simulated",
        simulation = paste0("sim_", j)
      )
    
    simulated_list[[j]] <- pred_dat %>%
      select(
        Iso_type, Stratification,
        Subject, t, value,
        estimate, simulation
      )
  }
  
  # ----------------------------------------
  # 6. Combine simulated datasets
  # ----------------------------------------
  
  simulated_dat <- bind_rows(simulated_list)
  
  observed_dat <- obs_dat %>%
    transmute(
      Iso_type,
      Stratification,
      Subject,
      t,
      value = result,
      estimate = "observed",
      simulation = "observed"
    )
  
  plot_dat <- bind_rows(
    simulated_dat,
    observed_dat
  ) %>%
    filter(is.finite(value), value > 0) %>%
    mutate(
      estimate = factor(
        estimate,
        levels = c("observed", "simulated")
      )
    )
  
  # ----------------------------------------
  # 7. Plot posterior predictive densities
  # ----------------------------------------
  
  ppc_plot <- ggplot(
    plot_dat,
    aes(
      x = value,
      color = estimate,
      group = simulation,
      linewidth = estimate,
      alpha = estimate
    )
  ) +
    geom_density() +
    scale_color_manual(
      values = c(
        observed = "black",
        simulated = "dodgerblue"
      )
    ) +
    scale_linewidth_manual(
      values = c(
        observed = 0.8,
        simulated = 0.3
      )
    ) +
    scale_alpha_manual(
      values = c(
        observed = 1,
        simulated = 0.3
      )
    ) +
    scale_x_log10() +
    theme_bw() +
    theme(
      legend.title = element_blank()
    ) +
    labs(
      title = "Posterior predictive check",
      x = "Assay value",
      y = "Density"
    )
  
  # ----------------------------------------
  # 8. Optional faceting
  # ----------------------------------------
  
  if (by_antigen) {
    
    if (dplyr::n_distinct(plot_dat$Stratification) > 1) {
      
      ppc_plot <- ppc_plot +
        ggplot2::facet_grid(
          rows = ggplot2::vars(Stratification),
          cols = ggplot2::vars(Iso_type),
          scales = "free_y"
        )
    } else {
      ppc_plot <- ppc_plot +
        ggplot2::facet_wrap(
          ~Iso_type,
          scales = "free_y"
        )
    }
  }
  
  return(ppc_plot)
}
