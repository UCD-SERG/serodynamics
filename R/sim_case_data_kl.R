#' Simulate longitudinal case follow-up data from a homogeneous population
#'
#' @section What changed in this version (and why):
#'
#' **ADDED -- `noise_sd`: measurement error on the log scale.**
#' Both models include an observation-error term:
#' `model.jags` line 54 (`logy ~ dnorm(mu.logy, prec.logy)`; the line-17 comment
#' calls `mu.logy` the value *"before Gaussian noise is added"*) and
#' `model_ch2.stan` line 110
#' (`logy ~ normal(two_phase_logk(...), inv_sqrt(prec_logy[k]))`).
#' This function previously returned `value = ab(...)` with no noise, so every
#' simulated point sat exactly on the curve and the residual was zero -- the
#' model was asked to estimate a parameter the data-generating process did not
#' have. Ezra: *"All the parameters that are in the chapter one model need to go
#' into `make_corr_curve_params`"* -- `prec.logy` is one of them.
#'
#' The noise is **multiplicative on the natural scale** (equivalently additive on
#' the log scale), matching the models:
#' `value = ab(...) * exp(N(0, noise_sd))`.
#' Adding it on the natural scale instead would (a) invert the error structure --
#' a log-scale SD of 0.29 is a ~29% error everywhere, whereas adding 0.29 to the
#' natural value is ~29% at baseline and ~0.2% at peak -- and (b) produce
#' negative values, which become `NaN` at `prep_ch2_standata()` line 49
#' (`logy <- log(value)`).
#'
#' `noise_sd` is per antigen-isotype because the models have a separate
#' `prec_logy[k]` for each. The posterior means from the `nepal_sees` fit are
#' `prec_logy = (11.969, 10.720)`, i.e. `noise_sd = c(0.2890, 0.3054)` for
#' `(HlyE_IgG, HlyE_IgA)`.
#'
#' **Backward compatible:** the default `noise_sd = 0` skips the noise step
#' entirely (it does not draw from the RNG), so existing seeded runs reproduce
#' bit-for-bit and the `rho = 0` nesting check is unaffected.
#'
#' @param curve_params a `curve_params`
#' object from [serocalculator::as_curve_params], assumed to be unstratified
#' @param n [integer] number of cases to simulate
#' @param max_n_obs maximum number of observations
#' @param dist_n_obs distribution of number of observations ([tibble::tbl_df])
#' @param followup_interval [integer] mean days between visits (used when
#'   `spacing = "uniform"`)
#' @param followup_variance [integer] jitter (+/- days) between visits (used
#'   when `spacing = "uniform"`)
#' @param antigen_isos [character] [vector]: which antigen isotypes to simulate
#' @param noise_sd [numeric] measurement-error SD **on the log scale**. Length 1
#'   (recycled) or one per element of `antigen_isos`; may be named by antigen.
#'   `0` (default) means no measurement error.
#' @param spacing [character] visit-time scheme passed to [sim_obs_times]:
#'   `"uniform"` (default, original equally-spaced visits) or `"log"` (new;
#'   log-spaced visits -- dense early, sparse late -- to capture both the peak
#'   and the decay tail). See [sim_obs_times].
#' @param t_min [numeric] first non-zero visit day for the log grid
#'   (default 3; used only when `spacing = "log"`)
#' @param t_max [numeric] last visit day for the log grid, reached by a case
#'   with `max_n_obs` visits (default 400; used only when `spacing = "log"`)
#'
#' @returns a `case_data` object
#' @export
#'
#' @examples
#' set.seed(1)
#' # original uniform scheme:
#' serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 100)
#'
#' # log-spaced visits with realistic measurement error:
#' serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 100, max_n_obs = 15, spacing = "log",
#'                 noise_sd = c(0.2890, 0.3054))
sim_case_data_kl <- function(
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

  # ---- ADDED: validate and align noise_sd to antigen_isos ----------------
  noise_sd <- as.numeric(noise_sd)
  if (any(!is.finite(noise_sd)) || any(noise_sd < 0)) {
    cli::cli_abort("{.arg noise_sd} must be finite and non-negative.")
  }
  if (length(noise_sd) == 1L) {
    noise_vec <- rep(noise_sd, length(antigen_isos))
  } else if (length(noise_sd) == length(antigen_isos)) {
    noise_vec <- noise_sd
  } else {
    cli::cli_abort(paste0(
      "{.arg noise_sd} must have length 1 or length(antigen_isos) = ",
      length(antigen_isos), "; got ", length(noise_sd), "."
    ))
  }
  if (!is.null(names(noise_sd)) && all(antigen_isos %in% names(noise_sd))) {
    noise_vec <- unname(noise_sd[antigen_isos])
  }
  names(noise_vec) <- antigen_isos
  add_noise <- any(noise_vec > 0)

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

  # ---- ADDED: multiplicative log-scale measurement error -----------------
  # Skipped entirely when noise_sd = 0 so the RNG stream (and therefore every
  # existing seeded result) is unchanged.
  if (add_noise) {
    biomarker_level_data <-
      biomarker_level_data |>
      mutate(
        value = .data$value *
          exp(stats::rnorm(
            dplyr::n(), 0,
            unname(noise_vec[as.character(.data$antigen_iso)])
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
  attr(to_return, "noise_sd") <- noise_vec   # ADDED: record what was simulated
  return(to_return)
}
