
test_that("prior_predict returns expected object", {
  
  pp <- prior_predict(
    mu_hyp_param = c(2.54, 2.54, 1, -2, -3),
    prec_hyp_param = rep(0.01, 5),
    omega_param = c(1, 50, 1, 10, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4, 1),
    n = 50,
    seed = 123
  )
  
  expect_s3_class(
    pp,
    "serodynamics_prior_predict"
  )
  
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
  
  expect_equal(
    s$parameter,
    c("y0", "y1", "t1", "alpha", "shape"))
  
  expect_true(
    all(c("q2.5", "median", "q97.5") %in% names(s)))
})

test_that("density output works", {
  
  pp <- prior_predict(
    mu_hyp_param = c(2.54, 2.54, 1, -2, -3),
    prec_hyp_param = rep(0.01, 5),
    omega_param = c(1, 50, 1, 10, 1),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4, 1),
    n = 50,
    type = "density",
    seed = 123
  )
  
  expect_identical(
    pp$type,
    "density"
  )
  
  expect_s3_class(
    pp$plot,
    "ggplot"
  )
})
