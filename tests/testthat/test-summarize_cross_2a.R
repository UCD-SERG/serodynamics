# Build a synthetic mcmc.list with KNOWN, constant lambda and prec.par so the
# posterior median equals the plugged-in values and c_p / rho_p are exact.
# This exercises summarize_cross_2a's column-name parsing AND its algebra
# without needing JAGS.

make_fixed_draws <- function(lambda_mat, prec_list, n_iter = 50) {
  k <- nrow(lambda_mat)
  p <- ncol(lambda_mat)
  cols <- list()
  for (i in 1:k) for (j in 1:p) cols[[sprintf("lambda[%d,%d]", i, j)]] <-
      lambda_mat[i, j]
  for (s in 1:k) for (i in 1:p) for (j in 1:p)
    cols[[sprintf("prec.par[%d,%d,%d]", s, i, j)]] <- prec_list[[s]][i, j]
  mat <- matrix(unlist(cols), nrow = n_iter, ncol = length(cols),
                byrow = TRUE, dimnames = list(NULL, names(cols)))
  coda::mcmc.list(coda::mcmc(mat))
}

test_that("summarize_cross_2a recovers known cross-covariance and correlation", {
  lambda <- matrix(c(0.3, 0.2, 0.0, 0.4, 0.1,
                     0.5, 0.3, 0.6, 0.2, 0.0),
                   nrow = 2, byrow = TRUE)
  prec1 <- diag(rep(2, 5))   # cov_w diag = 0.5
  prec2 <- diag(rep(2, 5))
  mcmc <- make_fixed_draws(lambda, list(prec1, prec2))

  res <- summarize_cross_2a(mcmc, antigens = c("HlyE_IgG", "HlyE_IgA"))

  # expected by hand
  c_true <- lambda[1, ] * lambda[2, ]
  v1 <- 0.5 + lambda[1, ]^2
  v2 <- 0.5 + lambda[2, ]^2
  rho_true <- c_true / sqrt(v1 * v2)

  expect_equal(res$cov_med, c_true, tolerance = 1e-8)
  expect_equal(res$cor_med, rho_true, tolerance = 1e-8)
  # constant draws -> CI collapses onto the point estimate
  expect_equal(res$cov_lo, res$cov_hi, tolerance = 1e-8)
  # zero-loading parameters give exactly zero cross-terms
  expect_equal(res$cov_med[3], 0)
  expect_equal(res$cor_med[5], 0)
})

test_that("summarize_cross_2a labels rows and the biomarker pair", {
  lambda <- matrix(0.2, nrow = 2, ncol = 5)
  mcmc <- make_fixed_draws(lambda, list(diag(rep(2, 5)), diag(rep(2, 5))))
  res <- summarize_cross_2a(mcmc, antigens = c("A", "B"))

  expect_equal(nrow(res), 5)
  expect_equal(res$param,
               c("log_y0", "log_y1_minus_y0", "log_t1",
                 "log_alpha", "log_shape_minus_1"))
  expect_true(all(res$pair == "A ~ B"))
})
