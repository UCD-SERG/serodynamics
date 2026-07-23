#' @title Simulate Longitudinal Case Follow-Up Data
#' @author Kwan Ho Lee
#' @description
#'  `sim_case_data()` simulates a longitudinal case-follow-up study from a set
#'  of antibody kinetic curve parameters. Each simulated participant is given
#'  one draw of curve parameters, a number of visits, and a schedule of visit
#'  days, and the antibody response is evaluated on those days.
#'
#'  The within-host models in this package treat an observed antibody
#'  measurement as the curve value plus Gaussian noise on the log scale, so
#'  simulated data need that noise too if they are to be used for parameter
#'  recovery. `noise_sd` is the log-scale standard deviation, which enters
#'  multiplicatively on the natural scale:
#'  \deqn{y_{\mathrm{obs}} = y(t) \cdot e^{\varepsilon},
#'    \quad \varepsilon \sim N(0, \sigma^2).}
#'  Adding the noise on the natural scale instead would shrink the relative
#'  error towards the peak of the curve and could return negative values.
#'
#'  `noise_sd` takes one value per antigen isotype, matching the per-isotype
#'  measurement precision the models estimate. The default of `0` gives
#'  noise-free data and does not draw from the random number generator, so
#'  previously seeded simulations give the same answer as before.
#'
#' @param curve_params a `curve_params` object from
#'   [serocalculator::as_curve_params], assumed to be unstratified
#' @param n [integer] number of cases to simulate
#' @param max_n_obs maximum number of observations
#' @param dist_n_obs distribution of number of observations ([tibble::tbl_df])
#' @param followup_interval [integer] mean days between visits, used when
#'   `spacing = "uniform"`
#' @param followup_variance [integer] jitter in days between visits, used when
#'   `spacing = "uniform"`
#' @param antigen_isos [character] [vector]: which antigen isotypes to simulate
#' @param noise_sd [numeric] measurement-error standard deviation on the log
#'   scale. Either a single value, recycled across isotypes, or one value per
#'   element of `antigen_isos`, optionally named by isotype. `0` (the default)
#'   simulates noise-free data.
#' @param spacing [character] visit-time scheme passed to [sim_obs_times]:
#'   `"uniform"` (the default, equally spaced visits) or `"log"` (log-spaced
#'   visits, dense early and sparse late, so that both the antibody peak and the
#'   decay tail are observed)
#' @param t_min [numeric] first non-zero visit day for the log grid, used when
#'   `spacing = "log"`
#' @param t_max [numeric] last visit day for the log grid, reached by a case
#'   with `max_n_obs` visits, used when `spacing = "log"`
#'
#' @returns a `case_data` object. The measurement-error standard deviations used
#'   are recorded in its `"noise_sd"` attribute.
#' @export
#'
#' @examples
#' # equally spaced visits, no measurement error (the original behaviour)
#' serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 100)
#'
#' # log-spaced visits with realistic measurement error
#' serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(
#'     n = 100,
#'     max_n_obs = 15,
#'     spacing = "log",
#'     noise_sd = c(0.29, 0.31)
#'   )
sim_case_data <- function(
    n,
    curve_params,
    antigen_isos = get_biomarker_levels(curve_params),
    max_n_obs = 10,
    dist_n_obs = tibble::tibble(n_obs = 1:max_n_obs, prob = 1 / max_n_obs),
    followup_interval = 7,
    followup_variance = 1,
    noise_sd = 0,
    spacing = c("uniform", "log"),
    t_min = 3,
    t_max = 400) {
  spacing <- match.arg(spacing)
  noise_vec <- resolve_noise_sd(noise_sd, antigen_isos)

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
        followup_interval = followup_interval,
        followup_variance = followup_variance,
        n_obs = .data$n_obs,
        spacing = spacing,
        max_n_obs = max_n_obs,
        t_min = t_min,
        t_max = t_max
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
    mutate(
      value = ab(
        t = .data$obs_time,
        y0 = .data$y0,
        y1 = .data$y1,
        t1 = .data$t1,
        alpha = .data$alpha,
        shape = .data$r
      )
    )

  if (any(noise_vec > 0)) {
    biomarker_level_data <-
      biomarker_level_data |>
      mutate(
        value = .data$value *
          exp(stats::rnorm(
            dplyr::n(),
            mean = 0,
            sd = unname(noise_vec[as.character(.data$antigen_iso)])
          ))
      )
  }

  to_return <-
    biomarker_level_data |>
    dplyr::rename(
      timeindays = "obs_time"
    ) |>
    as_case_data(
      id_var = "id",
      biomarker_var = "antigen_iso",
      time_in_days = "timeindays",
      value_var = "value"
    )
  attr(to_return, "noise_sd") <- noise_vec
  return(to_return)
}


# Align `noise_sd` to `antigen_isos`, validating length and sign --------------
resolve_noise_sd <- function(noise_sd, antigen_isos) {
  sd_values <- as.numeric(noise_sd)
  if (any(!is.finite(sd_values)) || any(sd_values < 0)) {
    cli::cli_abort("{.arg noise_sd} must be finite and non-negative.")
  }
  n_iso <- length(antigen_isos)
  if (!is.null(names(noise_sd)) && all(antigen_isos %in% names(noise_sd))) {
    noise_vec <- unname(sd_values[match(antigen_isos, names(noise_sd))])
  } else if (length(sd_values) == 1L) {
    noise_vec <- rep(sd_values, n_iso)
  } else if (length(sd_values) == n_iso) {
    noise_vec <- sd_values
  } else {
    cli::cli_abort(
      "{.arg noise_sd} must have length 1 or {n_iso}, not {length(sd_values)}."
    )
  }
  names(noise_vec) <- antigen_isos
  noise_vec
}
