test_that("cross_cov_from_loadings is the elementwise product of rows 1,2", {
  lam <- matrix(c(0.2, 0.3, 0.0, 0.4, 0.1,    # biomarker 1
                  0.5, 0.6, 0.7, -0.2, 0.0),  # biomarker 2
                nrow = 2, byrow = TRUE)
  expect_equal(
    cross_cov_from_loadings(lam),
    c(0.2 * 0.5, 0.3 * 0.6, 0.0 * 0.7, 0.4 * -0.2, 0.1 * 0.0)
  )
})

test_that("marginal_var_2a adds squared loadings to within-biomarker variance", {
  prec <- diag(c(4, 5, 10))          # cov_w = diag(0.25, 0.2, 0.1)
  lam_k <- c(0.3, 0.0, 0.2)
  expect_equal(
    marginal_var_2a(prec, lam_k),
    c(0.25 + 0.09, 0.2 + 0, 0.1 + 0.04)
  )
})

test_that("cross_cor_from_draw_2a matches manual correlation", {
  lam <- matrix(c(0.3, 0.0,
                  0.3, 0.0),
                nrow = 2, byrow = TRUE)
  prec1 <- diag(c(1 / (0.25 - 0.09), 1))  # so marginal var param1 = 0.25
  prec2 <- diag(c(1 / (0.25 - 0.09), 1))
  rho <- cross_cor_from_draw_2a(lam, prec1, prec2)
  # c_1 = 0.09, marg var each = 0.25 -> rho_1 = 0.09/0.25 = 0.36
  expect_equal(rho[1], 0.36, tolerance = 1e-8)
  expect_equal(rho[2], 0)  # zero loading -> zero correlation
})
