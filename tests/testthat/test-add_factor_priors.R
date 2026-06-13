test_that("add_factor_priors appends prec.lambda and zero_p without touching the rest", {
  priors <- list(n_params = 5, mu.hyp = matrix(0, 2, 5), wishdf = c(20, 20))

  out <- add_factor_priors(priors, prec_lambda = 0.5)

  # new elements added correctly
  expect_equal(out[["prec.lambda"]], 0.5)
  expect_equal(out[["zero_p"]], rep(0, 5))
  # existing elements untouched
  expect_equal(out[["n_params"]], priors[["n_params"]])
  expect_equal(out[["mu.hyp"]], priors[["mu.hyp"]])
  expect_equal(out[["wishdf"]], priors[["wishdf"]])
  # zero_p length tracks n_params
  expect_length(out[["zero_p"]], priors[["n_params"]])
})

test_that("add_factor_priors uses a sensible default and rejects bad prec_lambda", {
  priors <- list(n_params = 3)
  expect_equal(add_factor_priors(priors)[["prec.lambda"]], 0.25)  # default

  expect_error(add_factor_priors(priors, prec_lambda = 0), "positive")
  expect_error(add_factor_priors(priors, prec_lambda = -1), "positive")
  expect_error(add_factor_priors(priors, prec_lambda = c(1, 2)), "single")
})

test_that("make_inits_2a returns RNG seeds plus positive loading and mean starts", {
  mu_hyp <- matrix(c(0, 3, 2, -4, -1), nrow = 2, ncol = 5, byrow = TRUE)
  inits_fun <- make_inits_2a(n_antigen_isos = 2, n_params = 5, mu_hyp = mu_hyp)
  expect_type(inits_fun, "closure")

  init1 <- inits_fun(1)
  # RNG fields from initsfunction() are carried through
  expect_true(all(c(".RNG.seed", ".RNG.name") %in% names(init1)))
  # loading starts have the right shape and obey the model's lambda[1,] > 0 bound
  expect_equal(dim(init1[["lambda"]]), c(2, 5))
  expect_true(all(init1[["lambda"]] > 0))
  # mean starts equal the supplied hyper-means
  expect_equal(init1[["mu.par"]], mu_hyp)
  # different chains still initialise (distinct RNG seeds)
  expect_false(identical(inits_fun(1)[[".RNG.seed"]], inits_fun(2)[[".RNG.seed"]]))
})
