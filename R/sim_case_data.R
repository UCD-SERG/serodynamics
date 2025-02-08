#' Simulate longitudinal case follow-up data from a homogeneous population
#'
#' @param curve_params a `curve_params`
#' object from [serocalculator::as_curve_params], assumed to be unstratified
#' @param n [integer] number of cases to simulate
#' @param max_n_obs maximum number of observations
#' @param dist_n_obs distribution of number of observations ([tibble::tbl_df])
#' @param followup_interval [integer]
#' @param followup_variance [integer]
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
      antigen_iso =
        curve_params |> 
        serocalculator:::get_biomarker_levels()
    ) |>
    dplyr::left_join(
      curve_params,
      by = c(
        "antigen_iso" =
          curve_params |> serocalculator:::get_biomarker_names_var(),
        "iter"
      )
    ) |> 
    rowwise() |> 
    mutate(
      value = ab(t = .data$obs_time,
                 y0 = .data$y0,
                 y1 = .data$y1,
                 t1 = .data$t1,
                 alpha = .data$alpha, 
                 shape = .data$r)
    ) |> 
    ungroup()
  
  to_return = 
    biomarker_level_data |> 
    dplyr::rename(
      index_id = "id",
      timeindays = "obs_time") |> 
    structure(class = c("case_data", class(biomarker_level_data)),
              subject_id = "index_id",
              biomarker_var = "antigen_iso",
              timeindays = "timeindays",
              value_var = "value")
  
  return(to_return)
}
