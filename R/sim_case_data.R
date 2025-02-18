#' Simulate longitudinal case follow-up data from a homogeneous population
#'
#' @param curve_params a `curve_params`
#' object from [serocalculator::as_curve_params], assumed to be unstratified
#' @param n [integer] number of cases to simulate
#' @param max_n_obs maximum number of observations
#' @param dist_n_obs distribution of number of observations ([tibble::tbl_df])
#' @param followup_interval [integer]
#' @param followup_variance [integer]
#' @param antigen_isos [character] [vector]: which antigen isotypes to simulate
#'
#' @returns a `case_data` object
#' @export
#'
#' @examples
#' set.seed(1)
#' serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 100)
sim_case_data <- function(
    n,
    curve_params,
    antigen_isos = get_biomarker_levels(curve_params),
    max_n_obs = 10,
    dist_n_obs = tibble::tibble(n_obs = 1:max_n_obs, prob = 1 / max_n_obs),
    followup_interval = 7,
    followup_variance = 1) {
  case_level_data <-
    tibble::tibble(
      id = seq_len(n) |> as.character(),
      n_obs = sim_n_obs(dist_n_obs, n),
      iter = sample(curve_params$iter, size = n, replace = TRUE)
    )

  missing_antigen_isos <-
    setdiff(antigen_isos, curve_params |> get_biomarker_names())

  if (length(missing_antigen_isos) != 0) {
    cli::cli_abort(
      c(
        "Some biomarkers in {.arg antigen_isos} 
        are missing from `curve_params`: ",
        "{.str {missing_antigen_isos}}"
      )
    )
  }

  obs_level_data <-
    case_level_data |>
    dplyr::reframe(
      .by = c("id", "iter"),
      visit_num = seq_len(.data$n_obs),
      obs_time = sim_obs_times(
        followup_interval,
        followup_variance,
        .data$n_obs
      )
    )

  biomarker_level_data <-
    obs_level_data |>
    dplyr::reframe(
      .by = c("id", "visit_num", "obs_time", "iter"),
      antigen_iso = antigen_isos
    ) |>
    dplyr::left_join(
      curve_params,
      by = c(
        "antigen_iso" =
          curve_params |> serocalculator::get_biomarker_names_var(),
        "iter"
      )
    ) |>
    rowwise() |>
    mutate(
      value = ab(
        t = .data$obs_time,
        y0 = .data$y0,
        y1 = .data$y1,
        t1 = .data$t1,
        alpha = .data$alpha,
        shape = .data$r
      )
    ) |>
    ungroup()

  to_return <-
    biomarker_level_data |>
    dplyr::rename(
      index_id = "id",
      timeindays = "obs_time"
    ) |>
    as_case_data(
      id_var = "index_id",
      biomarker_var = "antigen_iso",
      time_in_days = "timeindays",
      value_var = "value"
    )

  return(to_return)
}
