#' @title Summarize cross-biomarker covariance from a Model 2a fit
#' @description
#' Reads posterior draws of the loadings (`lambda`) and within-biomarker
#' precisions (`prec.par`) from a Model 2a `mcmc.list` and returns, per kinetic
#' parameter, the posterior median and 95% credible interval of:
#'   - `c_p`   = same-parameter cross-biomarker covariance
#'              (\eqn{\lambda_{1,p}\lambda_{2,p}});
#'   - `rho_p` = the corresponding cross-biomarker correlation.
#'
#' The per-draw algebra is delegated to the small pure helpers
#' [cross_cov_from_loadings()] and [cross_cor_from_draw_2a()], so this function
#' only handles extraction and summarization.
#'
#' @param mcmc A [coda::mcmc.list] from [run_mod_2a()] (must contain monitored
#'   `lambda` and `prec.par` nodes).
#' @param antigens Optional length-2 [character] vector of biomarker labels,
#'   used only for the printed pair label.
#' @param param_names Optional length-`P` [character] vector of kinetic
#'   parameter names. Defaults to the log-scale names.
#' @param probs Quantiles for the credible interval. Default
#'   `c(0.025, 0.5, 0.975)`.
#'
#' @returns A [data.frame] with one row per kinetic parameter and columns
#'   `param`, `pair`, `cov_med`, `cov_lo`, `cov_hi`, `cor_med`, `cor_lo`,
#'   `cor_hi`.
#' @export
summarize_cross_2a <- function(mcmc,
                               antigens = NULL,
                               param_names = NULL,
                               probs = c(0.025, 0.5, 0.975)) {
  draws <- as.matrix(mcmc)
  dims <- jags_node_dims(colnames(draws))
  k <- dims[["lambda"]][1]
  p <- dims[["lambda"]][2]
  if (is.null(param_names)) {
    param_names <- c("log_y0", "log_y1_minus_y0", "log_t1",
                     "log_alpha", "log_shape_minus_1")[seq_len(p)]
  }

  n_draw <- nrow(draws)
  cov_draws <- matrix(NA_real_, n_draw, p)
  cor_draws <- matrix(NA_real_, n_draw, p)

  for (d in seq_len(n_draw)) {
    lambda_mat <- get_node_matrix(draws[d, ], "lambda", k, p)
    prec1 <- get_node_matrix(draws[d, ], "prec.par", p, p, slice = 1)
    prec2 <- get_node_matrix(draws[d, ], "prec.par", p, p, slice = 2)
    cov_draws[d, ] <- cross_cov_from_loadings(lambda_mat)
    cor_draws[d, ] <- cross_cor_from_draw_2a(lambda_mat, prec1, prec2)
  }

  pair_lab <- if (!is.null(antigens) && length(antigens) >= 2) {
    paste(antigens[1], antigens[2], sep = " ~ ")
  } else {
    "biomarker1 ~ biomarker2"
  }

  cov_q <- apply(cov_draws, 2, stats::quantile, probs = probs, na.rm = TRUE)
  cor_q <- apply(cor_draws, 2, stats::quantile, probs = probs, na.rm = TRUE)

  data.frame(
    param = param_names,
    pair = pair_lab,
    cov_med = cov_q[2, ], cov_lo = cov_q[1, ], cov_hi = cov_q[3, ],
    cor_med = cor_q[2, ], cor_lo = cor_q[1, ], cor_hi = cor_q[3, ],
    row.names = NULL
  )
}
