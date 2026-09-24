#' @title Draw kinetic parameters for a new individual
#'
#' @description
#' Draws individual-level kinetic parameters
#' for a hypothetical new individual,
#' one draw per posterior sample.
#'
#' The hierarchical model places each individual's parameter vector
#' at `MVN(mu.par, solve(prec.par))`,
#' so a new individual with no observed data
#' is a draw from that distribution.
#' Sampling after the fit is equivalent
#' to adding an all-missing subject to the model,
#' and avoids carrying a synthetic subject
#' through the sampler and the model output.
#'
#' Parameters are returned on the scale used by the model,
#' which is the scale named in the `Parameter` labels,
#' for example `log(y1 - y0)`.
#' Converting back to the natural scale is left to the caller,
#' because `y1` and `shape` are defined relative to other parameters.
#'
#' @param population_params A [data.frame] of population parameters,
#'   as attached to the output of [run_serodynamics()]
#'   when `with_pop_params = TRUE`.
#' @param n_draws Optional number of posterior draws to use
#'   from each isotype and stratification group.
#'   The default uses every draw.
#' @param call The calling environment, for error reporting.
#'
#' @returns A [tibble][tibble::tibble] with one row per parameter
#'   per retained draw,
#'   and columns `Iteration`, `Chain`, `Iso_type`, `Stratification`,
#'   `Parameter` and `value`.
#'
#' @keywords internal
#' @noRd
draw_new_individual_params <- function(population_params,
                                       n_draws = NULL,
                                       call = rlang::caller_env()) {
  draw_vars <- c("Iteration", "Chain", "Iso_type", "Stratification")
  required_vars <- c(
    draw_vars, "Population_Parameter", "Parameter", "value"
  )
  
  missing_vars <- setdiff(required_vars, names(population_params))
  if (length(missing_vars) > 0L) {
    cli::cli_abort(
      c(
        "{.arg population_params} is missing required column{?s}
         {.field {missing_vars}}.",
        "i" = "Was the model fit with {.code with_pop_params = TRUE}?"
      ),
      call = call
    )
  }
  
  if (!is.null(n_draws)) {
    retained_draws <-
      population_params |>
      dplyr::distinct(dplyr::pick(dplyr::all_of(draw_vars))) |>
      dplyr::slice_head(
        n = n_draws,
        by = dplyr::all_of(c("Iso_type", "Stratification"))
      )
    
    population_params <-
      population_params |>
      dplyr::semi_join(retained_draws, by = draw_vars)
  }
  
  new_individual_params <-
    population_params |>
    dplyr::reframe(
      draw_one_new_individual(
        dplyr::pick("Parameter", "Population_Parameter", "value"),
        call = call
      ),
      .by = dplyr::all_of(draw_vars)
    )
  
  return(new_individual_params)
}
