#' @title Simulate longitudinal case data with known cross-biomarker covariance
#' @description
#' End-to-end simulator for validating Model 2a. It draws correlated
#' subject-level parameters with [sim_params_2a()], evaluates the Chapter 1
#' two-phase curve [ab()] at a set of visit times for **two** biomarkers, adds
#' log-normal measurement noise, and returns a long [data.frame] in the
#' `serocalculator` case-data layout that [prep_data()] / [run_mod_2a()]
#' accept.
#'
#' Decomposed on purpose: the statistical truth lives in [sim_params_2a()], the
#' curve in [ab()], and this function only handles visit times, noise, and
#' reshaping.
#'
#' @param n [integer] number of subjects.
#' @param mu_g,mu_a,sigma_g,sigma_a,c_vec Model 2a truth, passed to
#'   [sim_params_2a()].
#' @param visit_times [numeric] vector of sampling times (days) shared by all
#'   subjects. Default `c(0, 7, 14, 28, 56, 90, 140, 200)`.
#' @param noise_sd Residual SD on the log scale. Default `0.2`.
#' @param biomarkers Length-2 [character] biomarker labels. Default
#'   `c("HlyE_IgG", "HlyE_IgA")`.
#' @param seed Optional RNG seed.
#'
#' @returns A [list] with `data` (the long case-data [data.frame]) and `truth`
#'   (the [sim_params_2a()] output, including `rho`).
#' @export
sim_case_data_2a <- function(n,
                             mu_g, mu_a, sigma_g, sigma_a, c_vec,
                             visit_times = c(0, 7, 14, 28, 56, 90, 140, 200),
                             noise_sd = 0.2,
                             biomarkers = c("HlyE_IgG", "HlyE_IgA"),
                             seed = NULL) {
  truth <- sim_params_2a(n, mu_g, mu_a, sigma_g, sigma_a, c_vec, seed = seed)
  p <- length(mu_g)
  n_visit <- length(visit_times)

  rows <- vector("list", n * 2)
  r <- 0L
  for (i in seq_len(n)) {
    for (k in 1:2) {
      pars <- truth$log_par[i, ((k - 1) * p + 1):(k * p)]
      y0 <- exp(pars[1])
      y1 <- y0 + exp(pars[2])
      t1 <- exp(pars[3])
      alpha <- exp(pars[4])
      shape <- exp(pars[5]) + 1
      vals <- vapply(
        visit_times,
        function(t) ab(t, y0, y1, t1, alpha, shape),
        numeric(1)
      )
      noisy <- exp(log(pmax(vals, 1e-3)) + stats::rnorm(n_visit, 0, noise_sd))
      r <- r + 1L
      rows[[r]] <- data.frame(
        id = as.character(i),
        timeindays = visit_times,
        antigen_iso = biomarkers[k],
        value = noisy,
        stringsAsFactors = FALSE
      )
    }
  }
  data <- do.call(rbind, rows) |>
    as_case_data(
      id_var = "id",
      biomarker_var = "antigen_iso",
      time_in_days = "timeindays",
      value_var = "value"
    )
  list(data = data, truth = truth)
}
