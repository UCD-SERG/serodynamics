#' @title Simulate longitudinal data for multiple biomarkers 
#' (analytic trajectory)
#' @author Kwan Ho Lee
#' @description
#' `simulate_multi_b_long()` draws subject-level latent parameters with a
#' Kronecker covariance \eqn{\Sigma_B \otimes \Sigma_P} (5 parameters per
#' biomarker), then generates noisy observations on a visit-time grid using
#' `two_phase_y()`.
#'
#' @param n_id Integer: number of subjects.
#' @param n_blocks Integer (B): number of biomarkers.
#' @param time_grid Numeric vector of visit times (days).
#' @param sigma_p 5x5 within-biomarker covariance of latent params
#'   (`log_y0`, `log_y1m0`, `log_t1`, `log_alpha`, `log(rho_m1)`).
#' @param sigma_b \code{B x B} across-biomarker covariance.
#' @param mu_latent_base Length-5 mean vector on the latent scale for a single
#'   biomarker (recycled across \code{n_blocks}).
#' @param meas_sd Length-\code{n_blocks} vector (or scalar) of log-scale
#'   measurement SDs per biomarker.
#'
#' @return A list with:
#' \itemize{
#'   \item \code{data}: tibble with columns \code{Subject}, \code{visit_num},
#'         \code{antigen_iso}, \code{time_days}, \code{value}.
#'   \item \code{truth}: list with \code{m_true}, \code{sigma_p}, 
#'   \code{sigma_b},
#'         \code{sigma_total}, \code{meas_sd}, \code{theta_latent}.
#' }
#'
#' @seealso two_phase_y
#' @export
#' @example inst/examples/examples-simulate_multi_b_long.R
simulate_multi_b_long <- function(
  n_id,
  n_blocks,
  time_grid,
  sigma_p,
  sigma_b,
  mu_latent_base = c(log(1.0), log(5.0), log(30), log(0.02), log(1.5)),
  meas_sd = rep(0.22, n_blocks)
) {
  # basic checks (adjust as needed)
  if (!all(dim(sigma_p) == c(5, 5))) cli::cli_abort("`sigma_p` must be 5x5.")
  if (!all(dim(sigma_b) == c(n_blocks, n_blocks))) {
    cli::cli_abort("`sigma_b` must be {n_blocks}x{n_blocks}.")
  }
  
  # 5B x 5B covariance for the Kronecker prior
  sigma_total <- kronecker(sigma_b, sigma_p)
  
  # per-biomarker means on latent scale (5 params × B biomarkers)
  m_true <- matrix(rep(mu_latent_base, n_blocks), nrow = 5, ncol = n_blocks)
  vec_m  <- as.vector(m_true) # length 5B
  
  # draw latent parameters (each subject gets length-5B vector)
  theta_latent <- mvtnorm::rmvnorm(n_id, mean = vec_m, sigma = sigma_total)
  
  # ---- build long data ----
  dat <- as.data.frame(theta_latent)
  colnames(dat) <- paste(
    rep(c("log_y0", "log_y1m0", "log_t1", "log_alpha", "log_rho_m1"), n_blocks),
    rep(seq_len(n_blocks), each = 5),
    sep = "_"
  )
  dat$Subject <- as.character(seq_len(n_id))
  
  dat <- tidyr::pivot_longer(
    dat,
    cols = -tidyselect::all_of("Subject"),
    names_to  = "param",
    values_to = "v"
  ) |>
    tidyr::separate(
      "param",
      into   = c("param", "biomarker"),
      sep    = "_(?=\\d+$)",
      remove = TRUE
    ) |>
    tidyr::pivot_wider(names_from = "param", values_from = "v") |>
    dplyr::mutate(
      y0    = exp(.data$log_y0),
      y1    = exp(.data$log_y1m0),
      t1    = exp(.data$log_t1),
      alpha = exp(.data$log_alpha),
      rho   = exp(.data$log_rho_m1) + 1
    ) |>
    tidyr::crossing(
      visit_num = seq_along(time_grid),
      time_days = time_grid
    ) |>
    dplyr::mutate(
      # namespace the helper so the linter knows it exists:
      y_true   = serodynamics:::two_phase_y(.data$time_days, .data$y0, 
                                            .data$y1, .data$t1, .data$alpha, 
                                            .data$rho),
      logy_true = log(pmax(.data$y_true, 1e-12)),
      bm_idx    = as.integer(.data$biomarker),
      logy_obs  = .data$logy_true + stats::rnorm(dplyr::n(), 0, 
                                                 meas_sd[.data$bm_idx]),
      value     = exp(.data$logy_obs)
    ) |>
    # avoid tidy-select; use data-mask with .data$
    dplyr::transmute(
      Subject    = .data$Subject,
      visit_num  = .data$visit_num,
      antigen_iso = .data$biomarker,
      time_days  = .data$time_days,
      value      = .data$value
    )
  
  list(
    data  = dat,
    truth = list(
      m_true       = m_true,
      sigma_p      = sigma_p,
      sigma_b      = sigma_b,
      sigma_total  = sigma_total,
      meas_sd      = meas_sd,
      theta_latent = theta_latent
    )
  )
}
