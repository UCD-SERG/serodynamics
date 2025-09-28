
#' @title Rhat Plot Diagnostics
#' @author Sam Schildhauer
#' @description
#'  plot_jags_Rhat() takes a [list] output from [serodynamics::run_mod()]
#'  to produce dotplots of potential scale reduction factors (Rhat) for each
#'  chain run in the mcmc estimation. Rhat values analyze the spread of chains
#'  compared to pooled values with a goal of observing rhat < 1.10 for
#'  convergence. 
#'  Defaults will produce every combination of antigen/antibody, parameters,
#'  and stratifications, unless otherwise specified.
#'  Antigen/antibody combinations and stratifications will vary by analysis.
#'  The antibody dynamic curve includes the following parameters:
#'  - y0 = baseline antibody concentration
#'  - y1 = peak antibody concentration
#'  - t1 = time to peak
#'  - r = shape parameter
#'  - alpha = decay rate
#' @param data A [list] outputted from run_mod().
#' @param iso Specify [character] string to produce plots of only a
#' specific antigen/antibody combination, entered with quotes. Default outputs
#' all antigen/antibody combinations.
#' @param param Specify [character] string to produce plots of only a
#' specific parameter, entered with quotes. Options include:
#' - `y0` = posterior estimate of baseline antibody concentration
#' - `y1` = posterior estimate of peak antibody concentration
#' - `t1` = posterior estimate of time to peak
#' - `r` = posterior estimate of shape parameter
#' - `alpha` = posterior estimate of decay rate
#' @param strat Specify [character] string to produce plots of specific
#' stratification entered in quotes.
#' @param id Specify [character] id in a [vector] format to produce plots for
#' specific individuals. Default is the `newperson` referring to the predictive
#' distribution.
#' @return A [list] of [ggplot2::ggplot] objects producing dotplots with rhat
#' values for all the specified input.
#' @export
#' @example inst/examples/examples-plot_jags_rhatdx.R

plot_jags_Rhat <- function(data,  # nolint: object_name_linter
                           iso = unique(data$Iso_type),
                           param = unique(data$Parameter),
                           strat = unique(data$Stratification),
                           id = c("newperson")) {
  
  attributes_jags <- data[["attributes"]]
  
  rhat_id_list <- list()
  for (h in id) {
    
    visualize_jags_sub <- data |>
      dplyr::filter(.data$Subject == h)
  
    rhat_strat_list <- list()
    for (i in strat) {
    
      visualize_jags_strat <- visualize_jags_sub |>
        dplyr::filter(.data$Stratification == i)

      # Creating open list to store ggplots
      rhat_out <- list()
      # Looping through the isos
      for (j in iso) {
        visualize_jags_plot <- visualize_jags_strat |>
          dplyr::filter(.data$Iso_type == j)
      
        # Will not loop through parameters, as we may want each to show on the
        # same plot by default.
        visualize_jags_plot <- visualize_jags_plot |>
          dplyr::filter(.data$Parameter %in% param)
      
        visualize_jags_plot <- visualize_jags_plot |>
          # Changing parameter name to reflect the input
          dplyr::mutate(Parameter = .data$Parameter,
                        value = log(.data$value))
        # Assigning attributes, which are needed to run ggs_rhat
        visualize_jags_plot <- add_jags_attrs(visualize_jags_plot, 
                                              attributes_jags)
        # Default order of main parameters
        param_levels <- c("alpha", "r", "t1", "y1", "y0")
        # Creating rhat dotplots
        rhatplot <- ggmcmc::ggs_Rhat(visualize_jags_plot) +
          ggplot2::theme_bw() +
          ggplot2::labs(title = "Rhat value",
                        subtitle = plot_title_fun(i, j),
                        x = "Rhat value") +
          ggplot2::scale_y_discrete(limits = intersect(param_levels,
                                             param))
        rhat_out[[j]] <- rhatplot
      }
      rhat_strat_list[[i]] <- rhat_out
    }
    #Printing only one plot if only one exists.
    if (sum(lengths(rhat_strat_list)) == 1) {
      rhat_strat_list <- rhat_strat_list[[1]][[iso]]
    } 
    rhat_id_list[[h]] <- rhat_strat_list
  }
  rhat_id_list
}
