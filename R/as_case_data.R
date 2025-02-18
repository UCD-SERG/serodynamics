#' Convert data into `case_data`
#'
#' @param data a [data.frame]
#' @param id_var
#' a [character] string naming the column in `data` denoting participant ID
#' @param biomarker_var
#' a [character] string naming the column in `data`
#' denoting which biomarker is being reported in `value_var`
#' (e.g. "antigen_iso")
#' @param time_in_days a [character] string naming the column in `data` with
#' elapsed time since seroconversion
#' @param value_var a [character] string naming the column in `data`
#' with biomarker measurements
#'
#' @returns a `case_data` object
#' @export
#'
#' @examples
#' set.seed(1)
#' serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 5) |>
#'   as_case_data(
#'     id_var = "index_id",
#'     biomarker_var = "antigen_iso",
#'     time_in_days = "timeindays",
#'     value_var = "value"
#'   )
#'
as_case_data <- function(
    data,
    id_var = "index_id",
    biomarker_var = "antigen_iso",
    value_var = "value",
    time_in_days = "timeindays") {
  data |>
    tibble::as_tibble() |>
    serocalculator::set_id_var(id_var) |> 
    structure(
      class = c("case_data", class(data)),
      biomarker_var = biomarker_var,
      timeindays = time_in_days,
      value_var = value_var
    )
}
