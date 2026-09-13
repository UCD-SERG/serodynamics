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
#'
#' @returns A [tibble][tibble::tibble] with columns `Parameter` and `value`,
#'   one row per parameter.
#'
#' @keywords internal
#' @noRd
draw_one_new_individual <- function(draw) {
  mean_rows <-
    draw |>
    dplyr::filter(.data$Population_Parameter == "mu.par")

  precision_rows <-
    draw |>
    dplyr::filter(.data$Population_Parameter == "prec.par")

  par_names <- mean_rows$Parameter

  precision <- rebuild_prec_matrix(precision_rows, par_names = par_names)

  sampled_values <- draw_mvn_from_precision(
    mu = mean_rows$value,
    prec = precision
  )

  new_individual <- tibble::tibble(
    Parameter = par_names,
    value = sampled_values
  )

  return(new_individual)
}
