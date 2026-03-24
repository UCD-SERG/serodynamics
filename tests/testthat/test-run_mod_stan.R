test_that("prep_data_stan() returns correctly structured Stan data list", {
  withr::local_seed(1)
  raw_data <-
    serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 5)

  prepped <- prep_data(raw_data, add_newperson = FALSE)
  stan_data <- prep_data_stan(prepped)

  expect_type(stan_data, "list")
  expect_named(
    stan_data,
    c("N", "K", "max_obs", "n_obs", "time_obs", "log_y_obs",
      "mu_hyp", "sigma_hyp")
  )
  expect_equal(stan_data$N, prepped$nsubj)
  expect_equal(stan_data$K, prepped$n_antigen_isos)
  expect_equal(stan_data$max_obs, unname(ncol(prepped$smpl.t)))
  expect_equal(stan_data$n_obs, as.integer(prepped$nsmpl))
  # No NA values allowed in Stan data arrays
  expect_false(anyNA(stan_data$time_obs))
  expect_false(anyNA(stan_data$log_y_obs))

  # Dimensions
  expect_equal(
    unname(dim(stan_data$time_obs)),
    c(stan_data$N, stan_data$max_obs)
  )
  expect_equal(
    unname(dim(stan_data$log_y_obs)),
    c(stan_data$N, stan_data$max_obs, stan_data$K)
  )

  # Hyperprior defaults
  expect_length(stan_data$mu_hyp, 5L)
  expect_length(stan_data$sigma_hyp, 5L)
  expect_true(all(stan_data$sigma_hyp > 0))
})

test_that("prep_data_stan() accepts custom hyperpriors", {
  withr::local_seed(2)
  raw_data <-
    serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 3)

  prepped <- prep_data(raw_data, add_newperson = FALSE)
  custom_mu    <- c(0, 5, 0, -3, -2)
  custom_sigma <- c(2, 100, 2, 50, 2)
  stan_data    <- prep_data_stan(prepped,
                                 mu_hyp    = custom_mu,
                                 sigma_hyp = custom_sigma)

  expect_equal(stan_data$mu_hyp, custom_mu)
  expect_equal(stan_data$sigma_hyp, custom_sigma)
})

test_that("run_mod_stan() gives informative error when rstan is absent", {
  skip_if(
    requireNamespace("rstan", quietly = TRUE),
    "rstan is installed — skipping 'rstan absent' test"
  )
  withr::local_seed(1)
  raw_data <-
    serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 3)

  expect_error(
    run_mod_stan(raw_data, chains = 1, iter = 10, warmup = 5),
    regexp = "rstan"
  )
})

# The remaining tests require rstan to be installed.
# They are skipped in environments where rstan is unavailable (e.g., CI
# runners without Stan). Run them locally after `install.packages("rstan")`.

test_that("run_mod_stan() returns an sr_model tibble", {
  skip_if_not_installed("rstan")
  withr::local_seed(42)
  sim_data <-
    serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 5)

  fit <- run_mod_stan(
    data    = sim_data,
    model   = "model_b",
    chains  = 1L,
    iter    = 200L,
    warmup  = 100L,
    seed    = 1L
  ) |>
    suppressWarnings()

  expect_s3_class(fit, "sr_model")
  expect_s3_class(fit, "tbl_df")
})

test_that("run_mod_stan() output has the expected columns", {
  skip_if_not_installed("rstan")
  withr::local_seed(42)
  sim_data <-
    serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 5)

  fit <- run_mod_stan(
    data    = sim_data,
    model   = "model_b",
    chains  = 1L,
    iter    = 200L,
    warmup  = 100L,
    seed    = 1L
  ) |>
    suppressWarnings()

  expected_cols <- c("Iteration", "Chain", "Parameter", "Iso_type",
                     "Stratification", "Subject", "value")
  expect_equal(names(fit), expected_cols)
})

test_that("run_mod_stan() output contains expected parameters", {
  skip_if_not_installed("rstan")
  withr::local_seed(42)
  sim_data <-
    serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 5)

  fit <- run_mod_stan(
    data    = sim_data,
    model   = "model_b",
    chains  = 1L,
    iter    = 200L,
    warmup  = 100L,
    seed    = 1L
  ) |>
    suppressWarnings()

  expect_setequal(
    unique(fit$Parameter),
    c("y0", "y1", "t1", "alpha", "shape")
  )
})

test_that("run_mod_stan() attaches Omega_eps and Sigma_eps attributes", {
  skip_if_not_installed("rstan")
  withr::local_seed(42)
  sim_data <-
    serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 5)

  fit <- run_mod_stan(
    data    = sim_data,
    model   = "model_b",
    chains  = 1L,
    iter    = 200L,
    warmup  = 100L,
    seed    = 1L
  ) |>
    suppressWarnings()

  omega <- attr(fit, "Omega_eps")
  sigma <- attr(fit, "Sigma_eps")

  # Both should be square matrices
  expect_true(is.matrix(omega))
  expect_true(is.matrix(sigma))
  expect_equal(nrow(omega), ncol(omega))
  expect_equal(nrow(sigma), ncol(sigma))

  # Correlation matrix: diagonal entries should be 1
  expect_equal(diag(omega), rep(1.0, nrow(omega)), tolerance = 1e-6)
})

test_that("run_mod_stan() attaches fitted_residuals attribute", {
  skip_if_not_installed("rstan")
  withr::local_seed(42)
  sim_data <-
    serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 5)

  fit <- run_mod_stan(
    data    = sim_data,
    model   = "model_b",
    chains  = 1L,
    iter    = 200L,
    warmup  = 100L,
    seed    = 1L
  ) |>
    suppressWarnings()

  fit_res <- attr(fit, "fitted_residuals")
  expect_s3_class(fit_res, "data.frame")
  expect_true(all(c("Subject", "Iso_type", "t", "fitted", "residual") %in%
                    names(fit_res)))
})

test_that("run_mod_stan() works with stratification", {
  skip_if_not_installed("rstan")
  withr::local_seed(1)
  strat1 <-
    serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 3) |>
    dplyr::mutate(grp = "A")
  withr::local_seed(2)
  strat2 <-
    serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 3) |>
    dplyr::mutate(grp = "B")
  dataset <- dplyr::bind_rows(strat1, strat2)

  fit <- run_mod_stan(
    data    = dataset,
    model   = "model_b",
    chains  = 1L,
    iter    = 200L,
    warmup  = 100L,
    strat   = "grp",
    seed    = 1L
  ) |>
    suppressWarnings()

  expect_s3_class(fit, "sr_model")
  expect_setequal(unique(fit$Stratification), c("A", "B"))
})
