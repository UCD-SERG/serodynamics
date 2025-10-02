set.seed(926)

test_that("simulate_multi_b_long() returns expected shapes", {
  n_blocks  <- 2
  time_grid <- c(0, 7, 14)
  
  sd_p <- c(0.35, 0.45, 0.25, 0.30, 0.25)
  R_p  <- matrix(0.25, 5, 5)
  diag(R_p) <- 1
  sigma_p <- diag(sd_p) %*% R_p %*% diag(sd_p)
  
  R_b  <- matrix(c(1, .5, .5, 1), n_blocks, n_blocks, byrow = TRUE)
  sd_b <- rep(0.6, n_blocks)
  sigma_b <- diag(sd_b) %*% R_b %*% diag(sd_b)
  
  sim <- simulate_multi_b_long(
    n_id = 3, n_blocks = n_blocks, time_grid = time_grid,
    sigma_p = sigma_p, sigma_b = sigma_b
  )
  
  # data tibble
  expect_s3_class(sim$data, "tbl_df")
  expect_setequal(
    names(sim$data),
    c("Subject", "visit_num", "antigen_iso", "time_days", "value")
  )
  # 3 ids * 2 biomarkers * 3 time points
  expect_equal(nrow(sim$data), 3 * n_blocks * length(time_grid))
  
  # truth bundle
  tr <- sim$truth
  expect_equal(dim(tr$m_true), c(5, n_blocks))
  expect_equal(dim(tr$sigma_p), c(5, 5))
  expect_equal(dim(tr$sigma_b), c(n_blocks, n_blocks))
  expect_equal(length(tr$meas_sd), n_blocks)
})
