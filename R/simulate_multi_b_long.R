#' @title Simulate longitudinal data (serodynamics trajectory)
#' @author Kwan Ho Lee
#' @description
#' `simulate_multi_b_long()` simulates subject-level latent parameters with a
#' Kronecker covariance \eqn{\Sigma_B \otimes \Sigma_P} (5 parameters per
#' biomarker), then generates noisy observations on a time grid. The expected
#' trajectory is computed directly using \code{serodynamics::ab()}.
#'
#' @param n_id Integer. Number of individuals to simulate.
#' @param n_blocks Integer. Number of biomarkers (blocks).
#' @param time_grid Numeric vector of observation times (days).
#' @param sigma_p 5×5 covariance matrix for within-biomarker parameters.
#' @param sigma_b \code{n_blocks}×\code{n_blocks} covariance across biomarkers.
#' @param mu_latent_base Numeric length-5 vector of means for the latent
#'   parameters (on log scale) per biomarker, in the order
#'   \code{(log y0, log(y1 - y0), log t1, log alpha, log(shape-1))}.
#' @param meas_sd Numeric. Measurement error SD(s) on the log scale; either a
#'   single value recycled to all biomarkers or a length-\code{n_blocks} vector.
#'
#' @return A list with:
#' \itemize{
#'   \item `data`: tibble with columns `Subject`, `visit_num`, `antigen_iso`,
#'         `time_days`, `value`.
#'   \item `truth`: list with `m_true`, `sigma_p`, `sigma_b`, `sigma_total`,
#'         `meas_sd`, and `theta_latent`.
#' }
#'
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
  # validations
  if (!all(dim(sigma_p) == c(5, 5))) {
    cli::cli_abort("`sigma_p` must be 5x5.")
  }
  if (!all(dim(sigma_b) == c(n_blocks, n_blocks))) {
    cli::cli_abort("`sigma_b` must be {n_blocks}x{n_blocks}.")
  }
  if (length(meas_sd) == 1L) {
    meas_sd <- rep(meas_sd, n_blocks)
  }
  if (length(meas_sd) != n_blocks) {
    cli::cli_abort("`meas_sd` must have length `n_blocks` (or be length 1).")
  }
  
  # Σ_total = Σ_B ⊗ Σ_P (dimension 5B x 5B)
  sigma_total <- kronecker(sigma_b, sigma_p)
  
  # per-biomarker means on latent scale (same base across biomarkers)
  m_true <- matrix(rep(mu_latent_base, n_blocks), nrow = 5, ncol = n_blocks)
  vec_m  <- as.vector(m_true) # length 5B
  
  # draw person-level latent parameters (each length 5B), then reshape to 5×B
  theta_latent <- mvtnorm::rmvnorm(n_id, mean = vec_m, sigma = sigma_total)
  
  dat <- purrr::map_dfr(seq_len(n_id), function(i) {
    mat <- matrix(theta_latent[i, ], nrow = 5, ncol = n_blocks)
    tibble::tibble(
      biomarker  = paste0("bm", seq_len(n_blocks)),
      log_y0     = mat[1, ],
      log_y1m0   = mat[2, ],
      log_t1     = mat[3, ],
      log_alpha  = mat[4, ],
      log_rho_m1 = mat[5, ]
    ) |>
      dplyr::mutate(
        y0      = exp(.data$log_y0),
        y1      = .data$y0 + exp(.data$log_y1m0),
        t1      = exp(.data$log_t1),
        alpha   = exp(.data$log_alpha),
        rho     = exp(.data$log_rho_m1) + 1,
        Subject = as.character(i)
      ) |>
      tidyr::crossing(visit_num = seq_along(time_grid) 
      ) |> # before: all pairs -> duplicates
      dplyr::mutate(time_days = time_grid[.data$visit_num]
      ) |> # after: one index, then look up the matching time
      dplyr::mutate(
        # call serodynamics:::ab() directly (already vectorized)
        y_true    = ab(
          t = .data$time_days, y0 = .data$y0, y1 = .data$y1,
          t1 = .data$t1, alpha = .data$alpha, shape = .data$rho
        ),
        logy_true = log(pmax(.data$y_true, 1e-12)),
        bm_idx    = as.integer(sub("^bm", "", .data$biomarker)),
        logy_obs  = .data$logy_true + stats::rnorm(dplyr::n(), 0, 
                                                   meas_sd[.data$bm_idx]),
        value     = exp(.data$logy_obs)
      ) |>
      dplyr::transmute(
        Subject     = .data$Subject,
        visit_num   = .data$visit_num,
        antigen_iso = .data$biomarker,
        time_days   = .data$time_days,
        value       = .data$value
      )
  })
  
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
