
#' @title Density Plot Diagnostics
#' @author Sam Schildhauer
#' @description
#'  plot_jags_dens() takes a [list] output from [serodynamics::run_mod()]
#'  to create density plots for each chain run in the mcmc estimation.
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
#' - `alpha` = posterior estimate of decay rate
#' - `r` = posterior estimate of shape parameter
#' - `t1` = posterior estimate of time to peak
#' - `y0` = posterior estimate of baseline antibody concentration
#' - `y1` = posterior estimate of peak antibody concentration
#' @param strat Specify [character] string to produce plots of specific
#' stratification entered in quotes.
#' @return A [base::list()] of [ggplot2::ggplot()] objects producing density
#' plots for all the specified input.
#' @export
#' @example inst/examples/examples-plot_jags_densitydx.R

plot_jags_dens <- function(data,
                           iso = unique(data$Iso_type),
                           param = unique(data$Parameter),
                           strat = unique(data$Stratification)) {
  
  attributes_jags <- data[["attributes"]]

  dens_strat_list <- list()
  for (i in strat) {

    visualize_jags_sub <- data |>
      dplyr::filter(.data$Stratification == i) |>
      dplyr::filter(.data$Subject == "newperson")

    # Creating open list to store ggplots
    density_out <- list()
    # Looping through the isos
    for (j in iso) {
      visualize_jags_plot <- visualize_jags_sub |>
        dplyr::filter(.data$Iso_type == j)

      # Will not loop through parameters, as we may want each to show on the
      # same plot by default.
      visualize_jags_plot <- visualize_jags_plot |>
        dplyr::filter(.data$Parameter %in% param)

      visualize_jags_plot <- visualize_jags_plot |>
        # Changing parameter name to reflect the input
        dplyr::mutate(Parameter = paste0("iso = ", j, ", parameter = ",
                                         .data$Parameter, ", strat = ",
                                         i),
                      value = log(.data$value))
      # Assigning attributes, which are needed to run ggs_density
      attributes(visualize_jags_plot) <- c(attributes(visualize_jags_plot),
                                           attributes_jags)
      # Creating density plot
      densplot <- ggmcmc::ggs_density(visualize_jags_plot) +
        ggplot2::theme_bw() +
        ggplot2::labs(x = "log(value)")
      density_out[[j]] <- densplot
    }
    dens_strat_list[[i]] <- density_out
  }
  dens_strat_list
}
