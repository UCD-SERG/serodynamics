# Retrieves and reshapes population-level `mu.par` posterior samples for
# `plot_serocurve(param_source = "population")`.
get_serocurve_population_params <- function(model, antigen_iso, strat) {
  pop_params <- attr(model, "population_params")
  if (is.null(pop_params)) {
    cli::cli_abort(
      c(
        paste0(
          "The {.arg model} object does not have",
          " a {.field population_params} attribute."
        ),
        "i" = paste0(
          "Re-fit the model with ",
          "{.code run_serodynamics(..., with_pop_params = TRUE)}."
        )
      )
    )
  }
  # The population_params tibble has columns:
  # Iteration, Chain, Parameter, Iso_type, Stratification,
  # Population_Parameter, value
  # Filter to mu.par rows only, then pivot wider and transform from log scale.
  pop_params |>
    dplyr::filter(
      .data$Population_Parameter == "mu.par",
      .data$Iso_type %in% .env$antigen_iso,
      .data$Stratification %in% .env$strat
    ) |>
    dplyr::select(
      all_of(
        c("Chain", "Iteration", "Parameter", "Iso_type", "Stratification",
          "value")
      )
    ) |>
    tidyr::pivot_wider(
      names_from = "Parameter",
      values_from = "value",
      names_prefix = "log_"
    ) |>
    dplyr::mutate(
      y0    = exp(.data$log_y0),
      y1    = .data$y0 + exp(.data$log_y1),
      t1    = exp(.data$log_t1),
      alpha = exp(.data$log_alpha),
      shape = exp(.data$log_shape) + 1
    ) |>
    dplyr::select(
      -dplyr::starts_with("log_")
    ) |>
    dplyr::mutate(
      Iso_type = factor(.data$Iso_type),
      Stratification = factor(.data$Stratification)
    )
}
