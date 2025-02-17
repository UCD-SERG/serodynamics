
#' @title Summary Diagnostics
#' @author Sam Schildhauer
#' @description
#'  plot_jags_summ() takes a [list] output from [serodynamics::run_mod()]
#'  to create summary statistics for each chain run in the mcmc estimation.
#'  Defaults will produce every combination of antigen/antibody, parameters,
#'  and stratifications, unless otherwise specified.
#'  Antigen/antibody combinations and stratifications will vary by analysis.
#'  The antibody dynamic curve includes the following parameters:
#'  - y0 = baseline antibody concentration
#'  - y1 = peak antibody concentration
#'  - t1 = time to peak
#'  - r = shape parameter
#'  - alpha = decay rate
#' @param name description
#' @param data A [base::list()] outputted from run_mod().
#' @param iso Specify [string] to produce diagnostics of only a specific
#' antigen/antibody combination, entered with quotes. Default outputs all
#' antigen/antibody combinations.
#' @param param Specify [string] to produce diagnostics of only a specific
#' parameter, entered with quotes. Options include:
#' - `alpha` = posterior estimate of decay rate
#' - `r` = posterior estimate of shape parameter
#' - `t1` = posterior estimate of time to peak
#' - `y0` = posterior estimate of baseline antibody concentration
#' - `y1` = posterior estimate of peak antibody concentration
#' @param strat Specify [string] to produce diagnostics of specific
#' stratification entered in quotes.
#' @return A [base::data.frame()] of producing summary statistics that are
#' produced from [ggmcmc::ggs_diagnostics()]. This includes the Geweke 
#' diagnostic, Potential Scale Reduction Factor Rhat, and the proportion of 
#' effective independent draws. 
#' input.
#' @export
#' @examples
#' if (!is.element(runjags::findjags(), c("", NULL))) {
#'   library(runjags)
#'   library(ggmcmc)
#'   set.seed(1)
#'   library(dplyr)
#'   strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
#'     sim_case_data(n = 100) |>
#'     mutate(strat = "stratum 2")
#'   strat2 <- serocalculator::typhoid_curves_nostrat_100 |>
#'     sim_case_data(n = 100) |>
#'     mutate(strat = "stratum 1")
#'
#'   Dataset <- bind_rows(strat1, strat2)
#'
#'   jags_out <- run_mod(
#'     data = Dataset, # The data set input
#'     file_mod = fs::path_package("serodynamics", "extdata/model.jags.r"),
#'     nchain = 4, # Number of mcmc chains to run
#'     nadapt = 100, # Number of adaptations to run
#'     nburn = 100, # Number of unrecorded samples before sampling begins
#'     nmc = 1000,
#'     niter = 2000, # Number of iterations
#'     strat = "strat"
#'   ) # Variable to be stratified
#' plot_jags_summ(
#'     data = jags_out, #A [serodynamics::run_mod()] [list] output.
#'     iso = "hlya_IgG", #A [string] specifying antigen/antibody of interest.
#'     param = "alpha",  #A [string] specifying parameter of interest.
#'     strat = "strat")  #A [string] specifying stratification of interest.
#'     }

plot_jags_summ <- function(data,
                           iso = unique(visualize_jags_sub$Iso_type),
                           param = unique(visualize_jags_sub$Parameter_sub),
                           strat = unique(visualize_jags$Stratification)) {
  visualize_jags <- data[["curve_params"]]
  attributes_jags <- data[["attributes"]]

  summ_strat_list <- list()
  for (i in strat) {

      visualize_jags_sub <- visualize_jags |>
        dplyr::filter(.data$Stratification == i)

    # Creating open list to store ggplots
    summary_out <- list()
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
                                         i))
      # Assigning attributes, which are needed to run ggs_summary
      attributes(visualize_jags_plot) <- c(attributes(visualize_jags_plot),
                                           attributes_jags)
      # Creating summary plot
      summplot <- ggmcmc::ggs_diagnostics(visualize_jags_plot)
      summary_out[[j]] <- summplot
    }
    summ_strat_list[[i]] <- summary_out
  }
  summ_strat_list
}
