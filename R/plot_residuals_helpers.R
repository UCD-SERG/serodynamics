#' @title Uses original data from correct source for `plot_residuals()`
#' @description
#' `get_original_data` will be used when a `facet_by_strat` or `color_by_strat` 
#' is called in order to access the stratifying variable. When the stratified 
#' variable occurs in the original `run_serodynamics()` call, the 
#' `original_data` attached to the output will be used. If the stratification 
#' was not used in the `run_serodynamics()` call, then the `original_data` will 
#' need to be attached as an option.
#' @inheritParams plot_residuals model original_data facet_by_strat
#' @inheritParams plot_residuals color_by_strat
#' @param facet_strat The facet stratification specified in `facet_by_strat`.
#' @param color_strat The color stratification specified in `facet_by_strat`.
#' @param strat The stratification specified in the original 
#' `run_serodynamics()` model.

#' @keywords internal
get_original_data <- function(
  model,
  original_data = NULL,
  strat = attr(model, "strat"),
  color_strat = FALSE,
  color_by_strat = NULL,
  facet_strat = FALSE,
  facet_by_strat = NULL
) {
  if (is.null(strat)) {
    strat <- NA_character_
  }
  
  needs_original_data <- (
    color_strat &&
      !is.null(color_by_strat) &&
      (is.na(strat) || color_by_strat != strat)
  ) || (
    facet_strat &&
      !is.null(facet_by_strat) &&
      (is.na(strat) || facet_by_strat != strat)
  )
  
  if (needs_original_data && is.null(original_data)) {
    cli::cli_abort(c(
      "x" = paste0(
        "Must include {.arg original_data} when stratifying by ",
        "{.arg facet_by_strat} or {.arg color_by_strat}."
      )
    ))
  }
  
  if (!needs_original_data) {
    original_data <- attr(model, "original_data")
  }
  
  if (is.null(original_data)) {
    cli::cli_abort(c(
      "x" = "{.arg model} has no {.arg original_data} attribute.",
      "i" = "Use output from {.fn run_serodynamics}."
    ))
  }
  
  original_data
}
