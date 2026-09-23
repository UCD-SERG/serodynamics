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