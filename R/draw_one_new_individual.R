#' @title Draw one new individual's parameters from a single posterior draw
#'
#' @description
#' Takes the population parameters belonging to one posterior draw
#' and returns a single sample from the implied individual-level distribution.
#'
#' The parameter order is taken from the `mu.par` rows
#' rather than from a fixed set,
#' so that a decay type with a different parameter set
#' needs no special case here.
#'
#' @param draw A [data.frame] of population parameters
#'   for a single posterior draw,
#'   with columns `Parameter`, `Population_Parameter` and `value`.
#' @inheritParams draw_new_individual_params
#'
#' @returns A [tibble][tibble::tibble] with columns `Parameter` and `value`,
#'   one row per parameter.
#'
#' @keywords internal
#' @noRd
draw_one_new_individual <- function(draw, call = rlang::caller_env()) {
  # Split the two parameter families: `mu.par` holds the population mean vector,
  # `prec.par` the precision matrix between parameters.
  mean_rows <-
    draw |>
    dplyr::filter(.data$Population_Parameter == "mu.par")

  precision_rows <-
    draw |>
    dplyr::filter(.data$Population_Parameter == "prec.par")

  # Take the parameter order from `mu.par` rather than a fixed set,
  # so a decay type with a different parameter set needs no special case.
  par_names <- mean_rows$Parameter

  # `unpack_jags()` stores each matrix cell as one pasted label,
  # so the matrix has to be reassembled before it can be used.
  precision <- rebuild_prec_matrix(
    precision_rows,
    par_names = par_names,
    call = call
  )

  # One draw for this posterior sample: the new individual's parameters are
  # a single realization from `MVN(mu.par, solve(prec.par))`.
  sampled_values <- draw_mvn_from_precision(
    mu = mean_rows$value,
    prec = precision,
    call = call
  )

  new_individual <- tibble::tibble(
    Parameter = par_names,
    value = sampled_values
  )

  return(new_individual)
}
