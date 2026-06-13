#' @title Summarize shared curve-parameter posteriors
#' @description
#' Extracts the quantities that Chapter 1 (`model.jags`) and Model 2a
#' (`model_2a.jags`) have in **common** so they can be compared directly:
#' the population means `mu.par[k, p]` and the within-biomarker variances.
#' For Model 2a the within-biomarker variance is the *marginal* variance
#' `diag(solve(prec.par[k])) + lambda[k, ]^2` (set `with_loadings = TRUE`);
#' for Chapter 1 there are no loadings, so it is just `diag(solve(prec.par[k]))`
#' (`with_loadings = FALSE`). Posterior medians are returned.
#'
#' Pure extraction/summary (delegates the variance algebra to
#' [marginal_var_2a()]); no fitting.
#'
#' @param mcmc A [coda::mcmc.list] (or a named draws [matrix]) containing
#'   monitored `mu.par` and `prec.par` (and `lambda` when `with_loadings`).
#' @param with_loadings [logical]; add the squared factor loadings to the
#'   within-biomarker variance (TRUE for Model 2a, FALSE for Chapter 1).
#' @param param_names Optional length-`P` parameter labels (defaults to the
#'   log-scale names).
#'
#' @returns A [data.frame] with columns `biomarker` (index), `param`,
#'   `mean_med` (median of `mu.par`), and `var_med` (median within-biomarker
#'   variance).
#' @export
summarize_curve_params_2a <- function(mcmc, with_loadings = FALSE,
                                      param_names = NULL) {
  draws <- as.matrix(mcmc)
  dims <- jags_node_dims(colnames(draws))
  k <- dims[["prec.par"]][1]
  p <- dims[["prec.par"]][2]
  if (is.null(param_names)) {
    param_names <- c("log_y0", "log_y1_minus_y0", "log_t1",
                     "log_alpha", "log_shape_minus_1")[seq_len(p)]
  }

  n_draw <- nrow(draws)
  # within-biomarker variance per draw, per biomarker
  var_arr <- array(NA_real_, c(n_draw, k, p))
  for (d in seq_len(n_draw)) {
    for (kk in seq_len(k)) {
      prec_k <- get_node_matrix(draws[d, ], "prec.par", p, p, slice = kk)
      lambda_k <- if (with_loadings) {
        get_node_matrix(draws[d, ], "lambda", k, p)[kk, ]
      } else {
        rep(0, p)
      }
      var_arr[d, kk, ] <- marginal_var_2a(prec_k, lambda_k)
    }
  }

  rows <- vector("list", k)
  for (kk in seq_len(k)) {
    mean_med <- vapply(
      seq_len(p),
      function(pp) stats::median(draws[, sprintf("mu.par[%d,%d]", kk, pp)]),
      numeric(1)
    )
    rows[[kk]] <- data.frame(
      biomarker = kk,
      param = param_names,
      mean_med = mean_med,
      var_med = apply(var_arr[, kk, , drop = FALSE], 3, stats::median),
      row.names = NULL
    )
  }
  do.call(rbind, rows)
}
