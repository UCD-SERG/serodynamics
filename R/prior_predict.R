#' @title Create Prior Predictive Plot
#' @description
#' Creates a prior predictive plot. The prior predictive plot can represent 
#' either the population or predictive level parameters. Output figures consist 
#' of either a density plot of the parameters or the varying plotted 
#' trajectories.
#' @inheritParams prep_priors mu_hyp_param prec_hyp_param omega_param 
#' @inheritParams prep_priors wishdf_param prec_logy_hyp_param
#' @param plot_type A [character] specifying if the prior predictive plot 
#' should be a `density` plot or a `serocurve` plot. 
#' @param param_source A [character] specifying if the plot should be based on
#' predictive parameters or population parameters. 
#'
#' @return A [ggplot2::ggplot] object.
#' @export
#' 
#' @example 
prior_predict <- function() {}
