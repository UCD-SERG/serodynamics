#' @title Plot Estimated Serodynamic Curves at Predictive or Population Level
#' @description
#' Plots the estimated antibody response curve derived from posterior samples
#' of population-level (`mu.par`) or the predictive distribution from a fitted
#' [run_serodynamics()] model.  A median curve with an optional 95% credible
#' interval ribbon is produced for each requested antigen-isotype and
#' stratification combination.
#'
#' @param model An `sr_model` object returned by [run_serodynamics()].
#' @param antigen_iso A [character] vector of antigen-isotype combinations to
#'   plot.  Defaults to all antigen-isotypes present in the subject-level
#'   draws of `model` (`model$Iso_type`); in normal usage these match the
#'   levels available in `attr(model, "population_params")`.
#' @param strat A [character] vector of stratification levels to include.
#'   Defaults to all stratification levels present in the subject-level
#'   draws of `model` (`model$Stratification`); in normal usage these match
#'   the levels available in `attr(model, "population_params")`.
#' @param param_source [character]; which posterior samples to use for the
#'   curve.  Options:
#'   - `"predictive"` (default): uses the predictive distribution for a new
#'     individual drawn from the population-level prior.
#'   - `"population"`: uses population-level `mu.par` samples stored
#'     in `attr(model, "population_params")`. Requires the model to have been
#'     fitted with `run_serodynamics(..., with_pop_params = TRUE)`.
#' @param show_ci [logical]; if [TRUE] (default), draws a 95% credible
#'   interval ribbon around the median curve.
#' @inheritParams plot_predicted_curve log_y log_x xlim
#' @param facet_by_strat [logical]; if [TRUE], facets the plot by
#'   stratification level.  When [FALSE] (default), different stratification
#'   levels are shown as different colours on the same panel.
#' @inheritDotParams add_serocurve_facets
#' @return A [ggplot2::ggplot] object.
#' @export
#'
#' @example inst/examples/examples-plot_serocurve.R
plot_serocurve <- function(
  model,
  antigen_iso = unique(model$Iso_type),
  strat = unique(model$Stratification),
  param_source = "predictive",
  show_ci = TRUE,
  log_y = FALSE,
  log_x = FALSE,
  xlim = NULL,
  facet_by_strat = FALSE,
  ...) {

  param_source <- match.arg(param_source, c("population", "predictive"))
  decay_type <- get_model_decay_type(model)

  antigen_iso_col <- "Iso_type"

  # ---- Retrieve posterior samples of curve parameters --------------------
  param_samples <- if (param_source == "population") {
    get_serocurve_pop_params(
      model,
      antigen_iso,
      strat,
      decay_type
    )
  } else {
    get_serocurve_pred_params(model, antigen_iso, strat)
  }

  # ---- Compute predicted curves and summarise to median + 95% CI ---------
  curve_summary <- summarize_serocurve_samples(
    param_samples,
    antigen_iso_col,
    xlim,
    decay_type
  )

  # ---- Determine whether to colour by stratification ---------------------
  n_strat <- length(unique(param_samples$Stratification))
  multi_strat <- n_strat > 1 && !facet_by_strat

  # ---- Build the ggplot --------------------------------------------------
  build_serocurve_plot(
    curve_summary, show_ci, multi_strat, antigen_iso = antigen_iso,
    antigen_iso_col, log_y, log_x, xlim, facet_by_strat,
    ...
  )
}
