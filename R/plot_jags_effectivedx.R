
#' @title Plot Effective Sample Size Diagnostics
#' @author Sam Schildhauer
#' @description
#'  plot_jags_effect() takes a [list] output from [serodynamics::run_mod()]
#'  to create summary diagnostics for each chain run in the mcmc estimation.
#'  Defaults will produce every combination of antigen/antibody, parameters,
#'  and stratifications, unless otherwise specified. At least 2 chains are 
#'  required to run function. 
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
#' @return A [list] of [ggplot2::ggplot] objects showing the 
#' proportion of effective samples taken/total samples taken for all parameter
#' iso combinations. The estimate with the highest proportion of effective
#' samples taken will be listed first.
#' @export
#' @example inst/examples/examples-plot_jags_effectivedx.R


plot_jags_effect <- function(data,
                             iso = unique(data$curve_params$Iso_type),
                             param = unique(data$curve_params$Parameter_sub),
                             strat = unique(data$curve_params$Stratification)) {
  visualize_jags <- data[["curve_params"]]
  attributes_jags <- data[["attributes"]]

  eff_strat_list <- list()
  for (i in strat) {

    visualize_jags_sub <- visualize_jags |>
      dplyr::filter(.data$Stratification == i) |>
      dplyr::filter(.data$Subject == "newperson")

    # Creating open list to store ggplots
    eff_out <- list()
    # Looping through the isos
    for (j in iso) {
      visualize_jags_plot <- visualize_jags_sub |>
        dplyr::filter(.data$Iso_type == j)

      # Will not loop through parameters, as we may want each to show on the
      # same plot by default.
      visualize_jags_plot <- visualize_jags_plot |>
        dplyr::filter(.data$Parameter_sub %in% param)

      visualize_jags_plot <- visualize_jags_plot |>
        # Changing parameter name to reflect the input
        dplyr::mutate(Parameter = .data$Parameter_sub)
      # Assigning attributes, which are needed to run ggs_density
      attributes(visualize_jags_plot) <- c(attributes(visualize_jags_plot),
                                           attributes_jags)

      # Creating density plot
      eff <- ggmcmc::ggs_effective(visualize_jags_plot) +
        ggplot2::theme_bw()  +
        ggplot2::labs(title = "Effective sample size",
                      subtitle = plot_title_fun(i, j),
                      x = "Proportion of effective samples") +
        ggplot2::scale_y_discrete(limits = c("alpha", "shape", "t1", "y1", 
                                             "y0"))
      eff_out[[j]] <- eff
    }
    eff_strat_list[[i]] <- eff_out
  }
  #Printing only one plot if only one exists.
  if (sum(lengths(eff_strat_list)) == 1) {
    eff_strat_list <- eff_strat_list[[1]][[iso]]
  } 
  eff_strat_list
}
