test_that("simulate_prior_predictive basic functionality", {
  withr::local_seed(123)

  # Create test data
  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 3)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  # Test single simulation
  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)

  expect_s3_class(sim_data, "prepped_jags_data")
  expect_true(attr(sim_data, "simulated_from_priors"))
  expect_equal(dim(sim_data$logy), dim(prepped_data$logy))
  expect_equal(dim(sim_data$smpl.t), dim(prepped_data$smpl.t))
})

test_that("simulate_prior_predictive with multiple simulations", {
  withr::local_seed(456)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  # Test multiple simulations
  n_sims <- 5
  sim_list <- simulate_prior_predictive(
    prepped_data,
    prepped_priors,
    n_sims = n_sims
  )

  expect_type(sim_list, "list")
  expect_length(sim_list, n_sims)
  expect_true(all(sapply(sim_list, inherits, "prepped_jags_data")))
})

test_that("simulate_prior_predictive respects seed", {
  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  # Generate two simulations with same seed
  sim1 <- simulate_prior_predictive(prepped_data, prepped_priors, seed = 789)
  sim2 <- simulate_prior_predictive(prepped_data, prepped_priors, seed = 789)

  expect_equal(sim1$logy, sim2$logy)
})

test_that("simulate_prior_predictive validates inputs", {
  withr::local_seed(101)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  # Wrong class for prepped_data
  expect_error(
    simulate_prior_predictive(list(a = 1), prepped_priors),
    "must be a.*prepped_jags_data"
  )

  # Wrong class for prepped_priors
  expect_error(
    simulate_prior_predictive(prepped_data, list(a = 1)),
    "must be a.*curve_params_priors"
  )

  # Mismatch in number of biomarkers
  wrong_priors <- prep_priors(max_antigens = 1)
  expect_error(
    simulate_prior_predictive(prepped_data, wrong_priors),
    "Mismatch between data and priors"
  )
})

test_that("simulate_prior_predictive with custom priors", {
  withr::local_seed(202)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)

  # Custom priors
  custom_priors <- prep_priors(
    max_antigens = prepped_data$n_antigen_isos,
    mu_hyp_param = c(1.0, 5.0, 0.5, -3.0, -2.0),
    prec_hyp_param = c(0.5, 0.0001, 0.5, 0.002, 0.5),
    omega_param = c(2.0, 30.0, 2.0, 8.0, 2.0),
    wishdf_param = 15,
    prec_logy_hyp_param = c(3.0, 0.8)
  )

  sim_data <- simulate_prior_predictive(prepped_data, custom_priors)

  expect_s3_class(sim_data, "prepped_jags_data")
  expect_true(attr(sim_data, "simulated_from_priors"))

  # Check that sim_params are stored
  sim_params <- attr(sim_data, "sim_params")
  expect_type(sim_params, "list")
  expect_true(all(c("y0", "y1", "t1", "alpha", "shape") %in% names(sim_params)))
})

test_that("simulate_prior_predictive produces finite values", {
  withr::local_seed(303)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 3)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)

  # Check that most values are finite (allowing for some NAs from structure)
  all_values <- as.vector(sim_data$logy)
  finite_values <- all_values[!is.na(all_values)]

  # At least 90% should be finite
  expect_true(sum(is.finite(finite_values)) / length(finite_values) > 0.9)
})

test_that("simulate_prior_predictive result consistency", {
  withr::local_seed(404)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)

  # Snapshot the structure and some values
  expect_snapshot_value(
    list(
      class = class(sim_data),
      dims = list(
        logy = dim(sim_data$logy),
        smpl_t = dim(sim_data$smpl.t)
      ),
      has_sim_params = !is.null(attr(sim_data, "sim_params")),
      simulated_from_priors = attr(sim_data, "simulated_from_priors")
    ),
    style = "deparse"
  )
})
