
#' @title Trace Plot Diagnostics
#' @author Sam Schildhauer
#' @description
#'  plot_jags_trace() takes a [list] output from [serodynamics::run_mod()]
#'  to create trace plots for each chain run in the mcmc estimation.
#'  Defaults will produce every combination of antigen/antibody, parameters,
#'  and stratifications, unless otherwise specified.
#'  Antigen/antibody combinations and stratifications will vary by analysis.
#'  The antibody dynamic curve includes the following parameters:
#'  - y0 = baseline antibody concentration
#'  - y1 = peak antibody concentration
#'  - t1 = time to peak
#'  - r = shape parameter
#'  - alpha = decay rate
#' @param data A [list] outputted from [run_mod()].
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
#' @param id Specify [character] id in a [vector] format to produce plots for
#' specific individuals. Default is the `newperson` referring to the predictive
#' distribution.
#' @return A [list] of [ggplot2::ggplot] objects producing trace
#' plots for all the specified input.
#' @export
#' @example inst/examples/examples-plot_jags_tracedx.R

plot_jags_trace <- function(data,
                            iso = unique(data$Iso_type),
                            param = unique(data$Parameter),
                            strat = unique(data$Stratification),
                            id = c("newperson")) {

  attributes_jags <- data[["attributes"]]
  
  trace_id_list <- list()
  for (h in id) {

    visualize_jags_sub <- data |>
      dplyr::filter(.data$Subject == h)
    
  trace_strat_list <- list()
  
  for (i in strat) {

    visualize_jags_sub <- data |>
      dplyr::filter(.data$Stratification == i)

    # Creating open list to store ggplots
    trace_out <- list()
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
                                         i))
      # Assigning attributes, which are needed to run ggs_density
      attributes(visualize_jags_plot) <- c(attributes(visualize_jags_plot),
                                           attributes_jags)
      # Creating density plot
      traceplot <- ggmcmc::ggs_traceplot(visualize_jags_plot) +
        ggplot2::theme_bw() +
        ggplot2::labs(x = "iterations", y = "parameter value") +
        ggplot2::theme(legend.position = "bottom") +
        ggplot2::scale_y_log10(labels = scales::label_comma())
      trace_out[[j]] <- traceplot
    }
    trace_strat_list[[i]] <- trace_out
  }
  #Printing only one plot if only one exists.
  if (sum(lengths(trace_strat_list) == 1)) {
    trace_strat_list <- trace_strat_list[[1]][[iso]]
  } 
  trace_id_list[[h]] <- trace_strat_list
  }
  trace_id_list
}
