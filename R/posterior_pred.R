#' @title Posterior predictive check
#' @author Sam Schildhauer
#' @description
#'  `posterior_pred()` conducts posterior predictive checks.
#' @param data A [base::data.frame()] with the following columns.
#'  - MCMC samples of posterior distribution of the person specific 
#' @param raw_dat A [base::data.frame()] with the following columns.
#' - each row is single OD measurement per ...
#' @param n_sample The number of simulated samples for posterior predictive
#' checks.
#' @param antigen_isos The antigen/isotype combinations to create posterior 
#' predictive plots for.
#' @param n_sim The number of simulations to run.
#' @returns A [list] of [ggplot2::ggplot] objects of posterior predictive checks.
#' @export
#' @example inst/examples/run_mod-examples.R
posterior_pred <- function(data = NA, 
                           raw_dat = NA,
                           by_antigen = FALSE,
                           n_sim = 4,
                           ...) {

  # First attaching prec.logy to the modeled data 
  mod_prec_logy <- attributes(data)$population_param |>
    dplyr::filter(.data$Population_params == "prec.logy") |>
    select(.data$Iteration, .data$Chain, .data$value, .data$Iso_type, 
           .data$Stratification) |>
    rename(prec_logy = .data$value)
  
  # First calculate mu_hat or the expected outcome based on given parameters
  mod_dat <- data |>
    tidyr::spread(.data$Parameter, .data$value)

  # Renaming pieces of raw data 
  obs_dat <- raw_dat |> 
    use_att_names() |>
    select(.data$Subject, .data$Iso_type, .data$t, .data$result)
    
  # Matching input data with modeled data
  matched_dat <- dplyr::right_join(mod_dat, obs_dat, 
                       by = c("Subject", "Iso_type"))
  # Change to all.y
  ## Rename objects so we know which objects are parameter samples 
    
  # Calculating fitted and residual
  fitted_dat <- matched_dat |>
    mutate(mu_hat = ab(.data$t, .data$y0, .data$y1, .data$t1,
                       .data$alpha, .data$shape))
    
  # The list of antigens that we will create a posterior predictive plots for.
  antigen_list <- list()
  
  for (i in antigen_isos) {
    
    prepare_plot_tab <- dplyr::tibble(Iso_type = NULL, value = NULL, estimate = NULL,
                           simulation = NULL)
      
    for (j in 1:n_sim) {
        
      if (by_antigen) {
       antigen_filter <- fitted_dat |>
        filter(.data$Iso_type == i)
      } else {
        antigen_filter <- fitted_dat
      }
       
      # Randomly sampling iteration and chain from the posterior distribution of the 
       # parameter by antigen/isotype, person ID, and time point
      sampled_posterior <- dplyr::slice_sample(fitted_dat, by = c("Subject", 
                                                                  "Iso_type",
                                                                  "t"))

      # Attaching precision values to sampled data set 
      sampled_posterior <- dplyr::left_join(sampled_posterior, mod_prec_logy, 
                                            by = c("Iteration", "Chain", 
                                                   "Iso_type", 
                                                   "Stratification"))
    
      # Calculating logy simulated using the modeled precision
      sampled_posterior <- sampled_posterior |>
        mutate(sd = 1 / sqrt(.data$prec_logy)) |>
        rowwise() |>
        mutate(value = exp(rnorm(n(), mean = log(.data$mu_hat), sd = .data$sd)))
      
      # Preparing data for rbind and ggplot
      sampled_posterior <- sampled_posterior |>
        select(.data$Iso_type, .data$value) |>
        mutate(estimate = "simulated", simulation = j)
      
      prepare_plot_tab <- rbind(prepare_plot_tab, sampled_posterior)
    }

  if (by_antigen) {
    obs_dat_prep <- obs_dat |>
      filter(.data$Iso_type == i) |>
      dplyr::select(.data$Iso_type, .data$result) |>
      dplyr::rename(value = .data$result) |>
      mutate(estimate = "observed", simulation = j)
    # Creating plot title 
    title <- paste0("Posterior predictive check for ", i)
  } else {
    obs_dat_prep <- obs_dat |>
      dplyr::select(.data$Iso_type, .data$result) |>
      dplyr::rename(value = .data$result) |>
      mutate(estimate = "observed", simulation = j)
    title <- "Posterior predictive check"
  }
    
  # Creating ggplot object
    ppc_plot <- ggplot2::ggplot() +
      ggplot2::geom_density(data = prepare_plot_tab,
                            ggplot2::aes(x = value, group = simulation), 
                            alpha = 0.2,
                            fill = NA,
                            color = "dodgerblue",
                            linewidth = 0.2) +
      ggplot2::geom_density(data = obs_dat_prep,
                            ggplot2::aes(x = value), 
                            alpha = 0.2,
                            fill = NA,
                            color = "grey20",
                            linewidth = 0.6) +
      ggplot2::theme_bw() +
      ggplot2::scale_x_log10() +
      ggplot2::labs(title = title, x = "OD value")
    
    if (by_antigen) {
    ag_list[[i]] <- ppc_plot
    } else {
      ag_list <- ppc_plot
    }
  }
  return(ag_list)
}
