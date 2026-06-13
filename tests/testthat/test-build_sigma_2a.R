test_that("build_sigma_2a places blocks correctly", {
  p <- 5
  sg <- diag(c(0.09, 0.16, 0.09, 0.16, 0.09))
  sa <- diag(c(0.10, 0.15, 0.08, 0.17, 0.10))
  cv <- c(0.03, 0.05, 0.0, 0.04, 0.0)

  sigma <- build_sigma_2a(sg, sa, cv)

  expect_equal(dim(sigma), c(2 * p, 2 * p))
  # within-biomarker blocks preserved
  expect_equal(sigma[1:p, 1:p], sg)
  expect_equal(sigma[(p + 1):(2 * p), (p + 1):(2 * p)], sa)
  # cross block is diagonal C
  expect_equal(diag(sigma[1:p, (p + 1):(2 * p)]), cv)
  off <- sigma[1:p, (p + 1):(2 * p)]
  expect_equal(sum(abs(off[upper.tri(off) | lower.tri(off)])), 0)
  # symmetric
  expect_equal(sigma, t(sigma))
})

test_that("c_vec = 0 recovers the Chapter 1 block-diagonal", {
  sg <- diag(c(0.09, 0.16, 0.09, 0.16, 0.09))
  sa <- sg
  sigma <- build_sigma_2a(sg, sa, rep(0, 5))
  expect_equal(sigma[1:5, 6:10], matrix(0, 5, 5))
})

test_that("build_sigma_2a rejects inadmissible cross-covariances", {
  sg <- diag(rep(0.1, 5))
  sa <- diag(rep(0.1, 5))
  # c_p = 0.2 > sqrt(0.1*0.1) = 0.1  -> not PD
  expect_error(build_sigma_2a(sg, sa, rep(0.2, 5)), "positive-definite")
})
