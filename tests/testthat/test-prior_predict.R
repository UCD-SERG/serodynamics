
test_that("prior_predict returns expected object", {
  
  pp <- prior_predict(
    mu_hyp_param = c(2.54, 2.54, 1, -2, -3),
    prec_hyp_param = rep(0.01, 5),
    omega_param = c(1, 50, 1, 10, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4, 1),
    n = 50,
    seed = 123,
    # log_y = TRUE
  )
  
  expect_s3_class(pp, "serodynamics_prior_predict")
  
  expect_s3_class(
    pp$plot,
    "ggplot"
  )
  
  expect_equal(
    nrow(pp$draws),
    50
  )
})

test_that("summary returns parameter quantiles", {
  testthat::announce_snapshot_file("prior_predict_summ.csv")
  
  pp <- prior_predict(
    mu_hyp_param = c(2.54, 2.54, 1, -2, -3),
    prec_hyp_param = rep(0.01, 5),
    omega_param = c(1, 50, 1, 10, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4, 1),
    n = 50,
    seed = 123
  )
  
  s <- summary(pp)
  
  expect_equal(s$parameter,
               c("y0", "y1", "t1", "alpha", "shape"))
  
  expect_true(all(c("q2.5", "median", "q97.5") %in% names(s)))
  
  s |>
  expect_snapshot_data(
    "prior_predict_summ",
    variant = darwin_variant()
  )
})

test_that("density output works", {
  
  pp <- prior_predict(
    mu_hyp_param = c(0.5, 5, 2, -3, -3),
    prec_hyp_param = c(0.5, 1.5, 3, 1, 0.5),
    omega_param = c(1, 2, 1, 1, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4, 1),
    n = 500,
    type = "density",
    seed = 123,
    log_y = TRUE
  )
  sd <- 1 / 0.5 ^ 2
  expect_identical(
    pp$type,
    "density"
  )
  
  expect_s3_class(
    pp$plot,
    "ggplot"
  )
})


test_that("Omitting inputs for errors", {
  
  prior_predict(
    mu_hyp_param = c(0.5, 5, 2, -3),
    prec_hyp_param = c(0.5, 1.5, 3, 1, 0.5),
    omega_param = c(1, 2, 1, 1, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4, 1)
  ) |>
    expect_error("`mu_hyp_param` must have")
  
  prior_predict(
    mu_hyp_param = c(0.5, 5, 2, -3, -3),
    prec_hyp_param = c(0.5, 1.5, 3, 1),
    omega_param = c(1, 2, 1, 1, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4, 1)
  ) |>
    expect_error("`prec_hyp_param` must have")
  
  prior_predict(
    mu_hyp_param = c(0.5, 5, 2, -3, -3),
    prec_hyp_param = c(0.5, 1.5, 3, 1, 0.5),
    omega_param = c(1, 2, 1, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4, 1)
  ) |>
    expect_error("`omega_param` must be")
  
  prior_predict(
    mu_hyp_param = c(0.5, 5, 2, -3, -3),
    prec_hyp_param = c(0.5, 1.5, 3, 1.5, 0.5),
    omega_param = c(1, 2, 1, 1, 1),
    wishdf_param = ,
    prec_logy_hyp_param = c(4, 1)
  ) |>
    expect_error("Missing: wish")
  
  prior_predict(
    mu_hyp_param = c(0.5, 5, 2, -3, -3),
    prec_hyp_param = c(0.5, 1.5, 3, 1, 0.5),
    omega_param = c(1, 2, 1, 1, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4)
  ) |>
    expect_error("`prec_logy_hyp_param` must contain")
  
  prior_predict(
    mu_hyp_param = c(0.5, 5, 2, -3, -3),
    prec_hyp_param = c(0.5, 1.5, 3, 1, -0.5),
    omega_param = c(1, 2, 1, 1, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4)
  ) |>
    expect_error("All values of `prec_hyp_param`")
  
  prior_predict(
    mu_hyp_param = c(0.5, 5, 2, -3, -3),
    prec_hyp_param = c(0.5, 1.5, 3, 1, -0.5),
    omega_param = c(1, 2, 1, 1, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4, 1)
  ) |>
    expect_error("All values of `prec_hyp_param`")
  
  prior_predict(
    mu_hyp_param = c(0.5, 5, 2, -3, -3),
    prec_hyp_param = c(0.5, 1.5, 3, 1, 0.5),
    omega_param = c(1, 2, 1, 1, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4, 1),
    n = 0.5
  ) |>
    expect_error("`n` must be a positive")
  
})
