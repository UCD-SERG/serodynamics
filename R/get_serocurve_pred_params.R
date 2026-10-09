# Retrieves and reshapes the "newperson" predictive-distribution posterior
# samples for `plot_serocurve(param_source = "predictive")`: a new
# individual drawn from the population-level prior.
get_serocurve_pred_params <- function(model, antigen_iso, strat) {
  newperson_rows <- model |>
    dplyr::filter(
      .data$Subject == "newperson",
      .data$Iso_type %in% .env$antigen_iso,
      .data$Stratification %in% .env$strat
    )

  if (nrow(newperson_rows) == 0) {
    cli::cli_abort(
      c(
        paste0(
          "No {.val newperson} subject found in {.arg model} for the ",
          "requested {.arg antigen_iso}/{.arg strat}."
        ),
        "i" = paste0(
          "Ensure the model was fit with a {.val newperson} subject ",
          "included."
        )
      )
    )
  }

  newperson_rows |>
    dplyr::select(
      all_of(
        c("Chain", "Iteration", "Parameter", "Iso_type", "Stratification",
          "value")
      )
    ) |>
    tidyr::pivot_wider(
      names_from = "Parameter",
      values_from = "value"
    ) |>
    dplyr::mutate(
      Iso_type = factor(.data$Iso_type),
      Stratification = factor(.data$Stratification)
    )
}
