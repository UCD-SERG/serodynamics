# Retrieves and reshapes population-level `mu.par` posterior samples for
# `plot_serocurve(param_source = "population")`.
get_serocurve_pop_params <- function(model, antigen_iso, strat,
                                     decay_type) {
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
    dplyr::mutate(
      # `Parameter` holds the log-scale labels `param_recode()` assigns
      # (e.g. `"log(y1 - y0)"`), not plain names, so recode to short
      # suffixes before pivoting or the resulting columns (`log_log(y0)`,
      # etc.) won't match the `log_y0`/etc. references below.
      Parameter = dplyr::recode_values(
        .data$Parameter,
        "log(y0)"        ~ "y0",
        "log(y1 - y0)"   ~ "y1",
        "log(t1)"        ~ "t1",
        "log(alpha)"     ~ "alpha",
        "log(shape - 1)" ~ "shape"
      )
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
      y0 = exp(.data$log_y0),
      y1 = .data$y0 + exp(.data$log_y1),
      t1 = exp(.data$log_t1),
      alpha = exp(.data$log_alpha),
      shape = if (.env$decay_type == "power") {
        exp(.data$log_shape) + 1
      } else {
        1
      }
    ) |>
    dplyr::select(
      -dplyr::starts_with("log_")
    ) |>
    dplyr::mutate(
      Iso_type = factor(.data$Iso_type),
      Stratification = factor(.data$Stratification)
    )
}
