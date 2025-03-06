
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
#' - `alpha` = posterior estimate of decay rate
#' - `r` = posterior estimate of shape parameter
#' - `t1` = posterior estimate of time to peak
#' - `y0` = posterior estimate of baseline antibody concentration
#' - `y1` = posterior estimate of peak antibody concentration
#' @param strat Specify [character] string to produce plots of specific
#' stratification entered in quotes.
#' @return A [base::list()] of [ggplot2::ggplot()] objects showing the 
#' proportion of effective samples taken/total samples taken for all parameter
#' iso combinations. The estimate with the highest proportion of effective
#' samples taken will be listed first.
#' @export
#' @examples
#' if (!is.element(runjags::findjags(), c("", NULL))) {
#'   library(runjags)
#'   library(ggmcmc)
#'   library(dplyr)
#'
#'   data <- serodynamics::nepal_sees_jags_post
#'
#' plot_jags_effect(
#'     data = data, #A [serodynamics::run_mod()] [list] output.
#'     iso = "HlyE_IgA", #A [character] string specifying
#'     #nantigen/antibody of interest.
#'     param = "alpha",  #A [character] string specifying parameter of
#'     # interest.
#'     strat = "typhi")  #A [character] string specifying
#'     # stratification of interest.
#'     }

plot_jags_effect <- function(data,
                             iso = unique(data$curve_params$Iso_type),
                             param = unique(data$curve_params$Parameter_sub),
                             strat = unique(data$curve_params$Stratification)) {
  visualize_jags <- data[["curve_params"]]
  attributes_jags <- data[["attributes"]]

  eff_strat_list <- list()
  for (i in strat) {

    visualize_jags_sub <- visualize_jags |>
      dplyr::filter(.data$Stratification == i)

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
        dplyr::mutate(Parameter = paste0("iso = ", j, ", parameter = ",
                                         .data$Parameter_sub, ", strat = ",
                                         i),
                      value = log(.data$value))
      # Assigning attributes, which are needed to run ggs_density
      attributes(visualize_jags_plot) <- c(attributes(visualize_jags_plot),
                                           attributes_jags)
      # Creating density plot
      eff <- ggmcmc::ggs_effective(visualize_jags_plot) +
        theme_bw()
      eff_out[[j]] <- eff
    }
    eff_strat_list[[i]] <- eff_out
  }
  eff_strat_list
}
