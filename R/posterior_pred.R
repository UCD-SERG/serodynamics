#' @title Posterior predictive check
#' @author Sam Schildhauer
#' @description
#'  `posterior_pred()` conducts posterior predictive checks.
#' @param data A [base::data.frame()] with the following columns.
#' @param raw_dat A [base::data.frame()] with the following columns.
#' @param n_sample The number of simulated samples for posterior predictive
#' checks.
#' @param antigen_isos The antigen/isotype combinations to create posterior 
#' predictive plots for.
#' @param n_sim The number of simulations to run.
#' @returns A [list] of [ggplot::ggplot] objects of posterior predictive checks. 
#' @export
#' @example inst/examples/run_mod-examples.R
posterior_pred <- function(data = NA, 
                           raw_dat = NA,
                           n_sample = 1000,
                           antigen_isos = unique(data$Iso_type),
                           n_sim = 4,
                           ...) {

  # First attaching prec.logy to the modeled data 
  prec_logy <- attributes(data)$population_param |>
    dplyr::filter(Population_params == "prec.logy") |>
    select(Iteration, Chain, value, Iso_type, Stratification) |>
    rename(prec_logy = value)
  
  # First calculate mu_hat or the expected outcome based on given parameters
  dat_fit <- data |>
    tidyr::spread(Parameter, value)

  # Renaming pieces of raw data 
    original_data <- raw_dat |> 
      use_att_names() |>
      select(.data$Subject, .data$Iso_type, .data$t, .data$result)
    
    # Matching input data with modeled data
    matched_dat <- merge(dat_fit, original_data, 
                         by = c("Subject", "Iso_type"),
                         all.x = TRUE)
    
    # Calculating fitted and residual
    fitted_dat <- matched_dat |>
      mutate(mu_hat = ab(.data$t, .data$y0, .data$y1, .data$t1,
                         .data$alpha, .data$shape))
    fitted_dat <- fitted_dat[complete.cases(fitted_dat$mu_hat),]
    
    ag_list <- list()
    for (i in antigen_isos) {
      plot_list <- list()
      
      for (j in 1:n_sim) {
        
        plot_prep <- fitted_dat |>
          filter(Iso_type == antigen_isos)
    smpl_mod <- fitted_dat[sample(nrow(fitted_dat), n_sample), ]
    
    # Attaching precision values to sampled data set 
    smpl_mod <- merge(smpl_mod, prec_logy, by = c("Iteration", "Chain", 
                                                  "Iso_type", "Stratification"), 
                           all.x = TRUE)
    
    # Calculating logy simulated using the modeled precision
    smpl_mod <- smpl_mod |>
      mutate(sd = 1/sqrt(.data$prec_logy)) |>
      rowwise() |>
      mutate(value = pmax(rnorm(n(), mean = mu_hat, sd = sd), 1e-3)) |>
      select(Iso_type, value) |>
      mutate(estimate = "simulated")
    
    original_data_prep <- original_data |>
      dplyr::select(Iso_type, result) |>
      dplyr::rename(value = result) |>
      mutate(estimate = "observed")
    
    plot_dat <- rbind(smpl_mod, original_data_prep)

    ppc_plot <- ggplot2::ggplot(data = plot_dat) +
      ggplot2::geom_density(ggplot2::aes(x = value, fill = estimate), 
                            alpha = 0.4) +
      ggplot2::theme_bw() +
      ggplot2::scale_x_log10() +
      ggplot2::labs(title = paste0("Posterior predictive check", i))
    
    plot_list[[j]] <- ppc_plot
      }
    ag_list[[i]] <- plot_list
    }
  return(ag_list)
}
