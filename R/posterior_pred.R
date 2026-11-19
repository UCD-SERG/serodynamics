
#' @title Posterior Predictive Check of Antibody Measurements
#'
#' @description
#' Generates replicated antibody measurements from individual-level
#' posterior kinetic parameters and population-level observation precision.
#' Compares observed and simulated antibody distributions using kernel
#' density estimates on a log10 assay-value scale.
#'
#' By default, all available antigen/isotype and stratification
#' combinations are included. Each combination receives its own
#' posterior predictive simulations.
#'
#' @details
#' For each antigen/isotype and stratification combination:
#'
#' 1. Observations are restricted to individuals represented in
#'    the posterior output.
#' 2. Complete joint posterior draws are identified using
#'    Iteration and Chain.
#' 3. A joint posterior draw is sampled for each simulation.
#' 4. Expected antibody concentrations are calculated using `ab()`.
#' 5. Lognormal observation error is added using the posterior
#'    observation precision.
#'
#' Simulations are evaluated at the observed sampling times.
#' Each simulated dataset contains one replicated measurement
#' for each retained observed measurement.
#'
#' Individuals without posterior estimates are excluded from
#' both observed and simulated distributions.
#'
#' The function checks completeness of individual-level parameters
#' and observation precision before selecting posterior draws.
#' Incomplete joint draws are not sampled.
#'
#' This posterior predictive check evaluates the marginal
#' distribution of antibody measurements. It does not directly
#' evaluate the timing of antibody rise or decay.
#'
#' @param data Long-format posterior draws containing Subject,
#'   Iso_type, Stratification, Iteration, Chain, Parameter, and value.
#'   Parameters must be on the natural scale.
#'   Must contain a `population_params` attribute.
#' @param raw_dat Observed antibody data. After `use_att_names()`,
#'   the data must contain Subject, Iso_type, t, and result,
#'   plus the stratification column when applicable.
#' @param iso Optional character vector selecting antigen/isotype
#'   combinations. NULL includes all available combinations.
#' @param strat Optional character vector selecting stratification
#'   groups. NULL includes all available groups.
#' @param n_sim Positive integer specifying the number of replicated
#'   datasets generated per antigen/isotype and stratification group.
#'   Default is 4.
#' @param decay_type Either "power" or "exponential".
#'   Defaults to the fitted model's decay_type attribute,
#'   or "power" if that attribute is absent.
#' @param seed Optional integer seed for reproducibility.
#' @param ... Reserved for future use.
#' @return A ggplot object containing observed and simulated density
#'   estimates. The underlying plotting data are available through
#'   attr(plot, "predictive_data").
#' @export
posterior_pred <- function(
    data,
    raw_dat,
    iso = NULL,
    strat = NULL,
    n_sim = 4,
    decay_type = NULL,
    ...) {
  
  # ---------------------------------------------------------
  # 1. Validate arguments
  # ---------------------------------------------------------
  if (!is.numeric(n_sim) || length(n_sim) != 1L || is.na(n_sim) ||
      !is.finite(n_sim) || n_sim < 1 || n_sim != floor(n_sim)) {
    stop("n_sim must be a positive integer.")}
  
  if (is.null(decay_type)) {
    decay_type <- attr(data, "decay_type")
    if (is.null(decay_type)) {
      decay_type <- "power"}}
  
  decay_type <- match.arg(decay_type, c("power", "exponential"))
  
  required <- c("alpha", "t1", "y0", "y1")
  
  if (decay_type == "power") {required <- c(required, "shape")}
  
  join_keys <- c("Subject", "Iso_type", "Stratification")
  draw_keys <- c("Iteration", "Chain")
  
  # ---------------------------------------------------------
  # 2. Extract population observation precision
  # ---------------------------------------------------------
  pop_params <- attr(data, "population_params")
  
  if (is.null(pop_params)) {
    stop("Missing population_params attribute.")
  }
  
  mod_prec_logy <- pop_params %>%
    dplyr::filter(.data$Population_Parameter == "prec.logy") %>%
    dplyr::transmute(Iteration, Chain, Iso_type, Stratification,
      prec_logy = as.numeric(as.character(value)))
  
  if (nrow(mod_prec_logy) == 0) {
    stop("No observation precision draws were found.")
  }
  
  # ---------------------------------------------------------
  # 3. Prepare individual posterior parameters
  # ---------------------------------------------------------
  mod_long <- as.data.frame(data) %>%
    dplyr::filter(Parameter %in% required, Subject != "newperson") %>%
    dplyr::mutate(value = as.numeric(as.character(value))) %>%
    dplyr::select(Subject, Iso_type, Stratification, Iteration, Chain, 
                  Parameter, value)
  
  if (nrow(mod_long) == 0) {
    stop("No individual-level posterior parameters found.")}
  
  mod_dat <- mod_long %>%
    tidyr::pivot_wider(id_cols = dplyr::all_of(c(join_keys, draw_keys)),
      names_from = Parameter, values_from = value)
  
  missing_columns <- setdiff(required, names(mod_dat))
  
  if (length(missing_columns) > 0) {
    stop("Missing posterior parameter columns: ",
         paste(missing_columns, collapse = ", "))}
  
  # ---------------------------------------------------------
  # 4. Prepare observed data
  # ---------------------------------------------------------
  obs_dat <- use_att_names(raw_dat)
  
  strat_col <- attr(data, "strat")
  
  if (!is.null(strat_col) && length(strat_col) == 1L && strat_col != "None") {
    if (strat_col != "Stratification" && strat_col %in% names(obs_dat)) {
      obs_dat <- obs_dat %>%
        dplyr::rename(Stratification = dplyr::all_of(strat_col))
    }
  } else if (!"Stratification" %in% names(obs_dat)) {
    obs_dat$Stratification <- "All"
  }
  if (!"Stratification" %in% names(obs_dat)) {
    stop("Could not identify the observed stratification column.")
  }
  obs_dat <- obs_dat %>%
    dplyr::mutate(
      Subject = as.character(Subject),
      Iso_type = as.character(Iso_type),
      Stratification = trimws(as.character(Stratification))) %>%
    dplyr::select(Subject, Iso_type, Stratification, t, result) %>%
    dplyr::filter(!is.na(t), !is.na(result))
  # ---------------------------------------------------------
  # 5. Optional antigen/isotype and stratification filters
  # ---------------------------------------------------------
  if (!is.null(iso)) {
    obs_dat <- obs_dat %>%
      dplyr::filter(Iso_type %in% iso)
    mod_dat <- mod_dat %>%
      dplyr::filter(Iso_type %in% iso)
    mod_prec_logy <- mod_prec_logy %>%
      dplyr::filter(Iso_type %in% iso)
  }
  if (!is.null(strat)) {
    obs_dat <- obs_dat %>%
      dplyr::filter(Stratification %in% strat)
    mod_dat <- mod_dat %>%
      dplyr::filter(Stratification %in% strat)
    mod_prec_logy <- mod_prec_logy %>%
      dplyr::filter(Stratification %in% strat)
  }
  if (nrow(obs_dat) == 0) {stop("No observed data match the selected groups.")}
  # ---------------------------------------------------------
  # 6. Match observed individuals to posterior parameters
  # ---------------------------------------------------------
  # All antigen/isotype and stratification combinations
  # represented in the fitted model
  model_groups <- mod_dat %>%
    dplyr::distinct(Iso_type, Stratification)
  
  # Identify modeled subjects
  modeled_subjects <- mod_dat %>%
    dplyr::distinct(
      dplyr::across(dplyr::all_of(join_keys))
    )
  
  # Identify unmatched observations
  unmatched <- obs_dat %>%
    dplyr::anti_join(modeled_subjects, by = join_keys)
  
  if (nrow(unmatched) > 0) {
    warning( nrow(unmatched), " observations do not match posterior subjects.")
  }
  
  # Keep observations that can be matched to the model
  obs_dat <- obs_dat %>%
    dplyr::semi_join(modeled_subjects, by = join_keys)
  
  # Identify groups with matching observed measurements
  matched_groups <- obs_dat %>%
    dplyr::distinct(Iso_type, Stratification)
  
  # Report model groups that cannot be simulated
  missing_groups <- model_groups %>%
    dplyr::anti_join(matched_groups, by = c("Iso_type", "Stratification"))
  
  if (nrow(missing_groups) > 0) {
    warning("The following modeled groups have no matching ",
            "observations and cannot be simulated:")
    print(missing_groups)
  }
  
  if (nrow(obs_dat) == 0) {
    stop("No observed measurements match posterior subjects.")
  }
  
  # Use all eligible antigen/isotype x stratification groups
  groups <- matched_groups
  
  # ---------------------------------------------------------
  # 7. Preprocess posterior draws and simulate
  # ---------------------------------------------------------
  # Create group identifiers once
  group_id <- function(x) {paste(x$Iso_type, x$Stratification, sep = "\r")}
  
  obs_groups <- split(obs_dat, group_id(obs_dat))
  person_groups <- split(mod_dat, group_id(mod_dat))
  precision_groups <- split(mod_prec_logy, group_id(mod_prec_logy))
  
  # Preallocate simulation output
  simulated_list <- vector("list",nrow(groups) * n_sim)
  
  counter <- 1L
  
  for (g in seq_len(nrow(groups))) {
    iso_g <- groups$Iso_type[g]
    strat_g <- groups$Stratification[g]
    
    key <- paste(iso_g, strat_g, sep = "\r")
    
    # Retrieve pre-split data: no filtering
    obs_g <- obs_groups[[key]]
    person_g <- person_groups[[key]]
    precision_g <- precision_groups[[key]]
    
    if (is.null(person_g) ||
        is.null(precision_g) ||
        nrow(person_g) == 0L ||
        nrow(precision_g) == 0L) {
      stop(
        "Missing posterior data for ",
        iso_g, " / ", strat_g
      )
    }
    
    # -------------------------------------------------------
    # 7a. Identify complete joint posterior draws ONCE
    # -------------------------------------------------------
    
    subjects_g <- unique(obs_g$Subject)
    expected_n_subjects <- length(subjects_g)
    
    # Only subjects represented in observations
    person_g <- person_g[
      person_g$Subject %in% subjects_g,
      ,
      drop = FALSE
    ]
    
    # Check parameter completeness once
    person_g$complete <- rowSums(
      is.finite(
        as.matrix(person_g[, required, drop = FALSE])
      )
    ) == length(required)
    
    # Create draw identifiers
    person_g$draw_id <- paste(
      person_g$Iteration,
      person_g$Chain,
      sep = "\r"
    )
    
    precision_g$draw_id <- paste(
      precision_g$Iteration,
      precision_g$Chain,
      sep = "\r"
    )
    
    # Split posterior draws once
    person_draws <- split(
      person_g,
      person_g$draw_id
    )
    
    precision_draws <- split(
      precision_g,
      precision_g$draw_id
    )
    
    # Validate complete joint draws once
    valid_person <- vapply(
      person_draws,
      function(x) {
        nrow(x) == expected_n_subjects &&
          !anyDuplicated(x$Subject) &&
          all(x$complete)
      },
      logical(1)
    )
    
    valid_precision <- vapply(
      precision_draws,
      function(x) {
        nrow(x) == 1L &&
          is.finite(x$prec_logy[[1]]) &&
          x$prec_logy[[1]] > 0
      },
      logical(1)
    )
    
    available_draws <- intersect(
      names(person_draws)[valid_person],
      names(precision_draws)[valid_precision]
    )
    
    if (length(available_draws) == 0L) {
      stop(
        "No complete posterior draws for ",
        iso_g, " / ", strat_g
      )
    }
    
    # Remove invalid draws from lookup structures
    person_draws <- person_draws[available_draws]
    
    precision_values <- vapply(
      precision_draws[available_draws],
      function(x) x$prec_logy[[1]],
      numeric(1)
    )
    
    # -------------------------------------------------------
    # 7b. Precompute observation-to-subject mapping
    # -------------------------------------------------------
    
    # Every valid draw has the same subjects.
    # Establish a consistent subject ordering once.
    subject_order <- subjects_g
    
    person_draws <- lapply(
      person_draws,
      function(x) {
        x[match(subject_order, x$Subject), , drop = FALSE]
      }
    )
    
    # Maps each observation to its subject's parameter row
    obs_index <- match(obs_g$Subject, subject_order)
    
    if (anyNA(obs_index)) {
      stop("Could not match observations to subjects.")
    }
    
    # Sample all joint draws for this group at once
    sampled_draws <- sample(available_draws, size = n_sim, replace = TRUE)
    
    # -------------------------------------------------------
    # 7c. Generate replicated datasets
    # -------------------------------------------------------
    
    for (j in seq_len(n_sim)) {
      draw_j <- sampled_draws[[j]]
      # Direct lookup: no filtering or joining
      person_j <- person_draws[[draw_j]]
      prec_j <- precision_values[[draw_j]]
      
      # Match parameters using precomputed indices
      params_j <- person_j[
        obs_index,
        ,
        drop = FALSE
      ]
      
      # Calculate expected antibody concentrations
      ab_args <- list(t = obs_g$t, y0 = params_j$y0, y1 = params_j$y1,
                      t1 = params_j$t1, alpha = params_j$alpha, 
                      decay_type = decay_type)
      
      if (decay_type == "power") {
        ab_args$shape <- params_j$shape
      }
      
      mu_hat <- do.call(ab, ab_args)
      
      if (any(!is.finite(mu_hat)) ||
          any(mu_hat <= 0)) {
        stop(
          "Nonpositive or invalid predicted antibody ",
          "values for ", iso_g, " / ", strat_g
        )
      }
      
      # Add lognormal observation error
      simulated_values <- stats::rlnorm(
        n = length(mu_hat),
        meanlog = log(mu_hat),
        sdlog = 1 / sqrt(prec_j)
      )
      
      # Store only the columns needed for plotting
      simulated_list[[counter]] <- data.frame(
        Iso_type = obs_g$Iso_type,
        Stratification = obs_g$Stratification,
        Subject = obs_g$Subject,
        t = obs_g$t,
        value = simulated_values,
        estimate = "simulated",
        simulation = paste0("sim_", j)
      )
      
      counter <- counter + 1L
    }
  }
  
  
  # ---------------------------------------------------------
  # 8. Combine observed and simulated measurements
  # ---------------------------------------------------------
  
  simulated_dat <- dplyr::bind_rows(simulated_list)
  
  observed_dat <- obs_dat %>%
    dplyr::transmute(Iso_type, Stratification, Subject, t, value = result,
      estimate = "observed", simulation = "observed")
  
  plot_dat <- dplyr::bind_rows(simulated_dat, observed_dat) %>%
    dplyr::filter(is.finite(value), value > 0) %>%
    dplyr::mutate(estimate = factor(estimate, 
                                    levels = c("observed", "simulated")))
  
  # ---------------------------------------------------------
  # 9. Plot posterior predictive densities
  # ---------------------------------------------------------
  
  ppc_plot <- ggplot2::ggplot(plot_dat,
    ggplot2::aes(x = value, color = estimate, 
                 group = interaction(estimate, simulation),
                 linewidth = estimate, alpha = estimate)) +
    ggplot2::geom_density(na.rm = TRUE) +
    ggplot2::scale_color_manual(values = c(observed = "black", 
                                           simulated = "dodgerblue")) +
    ggplot2::scale_linewidth_manual(values = c(observed = 0.8, simulated = 0.3)
                                    ) +
    ggplot2::scale_alpha_manual(values = c(observed = 1, simulated = 0.3)) +
    ggplot2::scale_x_log10() +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.title = ggplot2::element_blank(),
      legend.position = "top",
      strip.text.y.right = ggplot2::element_text(
        size = 7
      ),
      panel.grid.minor = ggplot2::element_blank()
    ) +
    ggplot2::labs(
      title = "Posterior predictive check",
      x = "Assay value",
      y = "Density"
    )
  
  # ---------------------------------------------------------
  # 10. Automatic faceting
  # ---------------------------------------------------------
  
  strat_levels <- unique(
    as.character(mod_dat$Stratification)
  )
  
  plot_dat <- plot_dat %>%
    dplyr::mutate(
      Stratification = factor(
        Stratification,
        levels = strat_levels
      )
    )
  
  ppc_plot <- ppc_plot +
    ggh4x::facet_grid2(
      rows = ggplot2::vars(Stratification),
      cols = ggplot2::vars(Iso_type),
      scales = "free",
      independent = "y",
      drop = FALSE
    )
  
  # Retain simulation data for diagnostics
  attr(ppc_plot, "predictive_data") <- plot_dat
  
  return(ppc_plot)
}
