# Synthetic constant-draw mcmc.list with known mu.par, prec.par, lambda so the
# medians equal the plugged-in values. Verifies the shared-parameter extraction
# used by compare_mod_2a() without needing JAGS.

make_curve_draws <- function(mu_par, prec_list,
                             lambda_mat = NULL, n_iter = 40) {
  k <- nrow(mu_par)
  p <- ncol(mu_par)
  cols <- list()
  for (i in 1:k) for (j in 1:p) cols[[sprintf("mu.par[%d,%d]", i, j)]] <-
    mu_par[i, j]
  for (s in 1:k) for (i in 1:p) for (j in 1:p)
    cols[[sprintf("prec.par[%d,%d,%d]", s, i, j)]] <- prec_list[[s]][i, j]
  if (!is.null(lambda_mat)) {
    for (i in 1:k) for (j in 1:p)
      cols[[sprintf("lambda[%d,%d]", i, j)]] <- lambda_mat[i, j]
  }
  mat <- matrix(unlist(cols), nrow = n_iter, ncol = length(cols),
                byrow = TRUE, dimnames = list(NULL, names(cols)))
  coda::mcmc.list(coda::mcmc(mat))
}

test_that("summarize_curve_params_2a returns means and variances", {
  mu <- matrix(c(0, 3, 2, -4, -1,
                 0.2, 3.1, 2.2, -3.8, -1.1), nrow = 2, byrow = TRUE)
  prec1 <- diag(c(10, 5, 20, 4, 8))   # cov diag = 1/diag
  prec2 <- diag(c(8, 6, 15, 5, 9))
  mcmc <- make_curve_draws(mu, list(prec1, prec2))
  
  s <- summarize_curve_params_2a(mcmc, with_loadings = FALSE)
  
  expect_equal(nrow(s), 10)
  # means recovered per biomarker
  expect_equal(s$mean_med[s$biomarker == 1], mu[1, ])
  expect_equal(s$mean_med[s$biomarker == 2], mu[2, ])
  # within-biomarker variance = 1/prec diagonal (no loadings)
  expect_equal(s$var_med[s$biomarker == 1], 1 / diag(prec1))
  expect_equal(s$var_med[s$biomarker == 2], 1 / diag(prec2))
})

test_that("with_loadings adds squared loadings to the variance (Model 2a)", {
  mu <- matrix(0, nrow = 2, ncol = 5)
  prec1 <- diag(rep(4, 5))   # cov diag 0.25
  prec2 <- diag(rep(4, 5))
  lambda <- matrix(c(0.3, 0.0, 0.2, 0.1, 0.0,
                     0.4, 0.5, 0.0, 0.2, 0.1), nrow = 2, byrow = TRUE)
  mcmc <- make_curve_draws(mu, list(prec1, prec2), lambda)
  
  s <- summarize_curve_params_2a(mcmc, with_loadings = TRUE)
  expect_equal(s$var_med[s$biomarker == 1], 0.25 + lambda[1, ]^2)
  expect_equal(s$var_med[s$biomarker == 2], 0.25 + lambda[2, ]^2)
})
