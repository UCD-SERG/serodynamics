test_that("plot_prior_predictive basic functionality", {
  withr::local_seed(123)

  # Create test data
  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  p <- plot_prior_predictive(sim_data)

  expect_s3_class(p, "ggplot")
})

test_that("plot_prior_predictive with multiple simulations", {
  withr::local_seed(456)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_list <- simulate_prior_predictive(
    prepped_data,
    prepped_priors,
    n_sims = 5
  )
  p <- plot_prior_predictive(sim_list)

  expect_s3_class(p, "ggplot")
})

test_that("plot_prior_predictive with observed data overlay", {
  withr::local_seed(789)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  p <- plot_prior_predictive(sim_data, original_data = prepped_data)

  expect_s3_class(p, "ggplot")

  # Check that the plot includes observed data in subtitle
  expect_true(grepl("observed", p$labels$subtitle, ignore.case = TRUE))
})

test_that("plot_prior_predictive on natural scale", {
  withr::local_seed(101)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  p <- plot_prior_predictive(sim_data, log_scale = FALSE)

  expect_s3_class(p, "ggplot")
  expect_true(grepl("Antibody Level", p$labels$y))
  expect_false(grepl("Log", p$labels$y))
})

test_that("plot_prior_predictive on log scale", {
  withr::local_seed(202)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  p <- plot_prior_predictive(sim_data, log_scale = TRUE)

  expect_s3_class(p, "ggplot")
  expect_true(grepl("Log", p$labels$y))
})

test_that("plot_prior_predictive respects max_traj parameter", {
  withr::local_seed(303)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  # Generate many simulations
  sim_list <- simulate_prior_predictive(
    prepped_data,
    prepped_priors,
    n_sims = 200
  )

  # Should inform about limiting trajectories
  expect_message(
    plot_prior_predictive(sim_list, max_traj = 50),
    "Plotting 50 of 200 simulations"
  )
})

test_that("plot_prior_predictive without points", {
  withr::local_seed(404)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  p <- plot_prior_predictive(
    sim_data,
    original_data = prepped_data,
    show_points = FALSE
  )

  expect_s3_class(p, "ggplot")
})

test_that("plot_prior_predictive with custom alpha", {
  withr::local_seed(505)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  p <- plot_prior_predictive(sim_data, alpha = 0.1)

  expect_s3_class(p, "ggplot")
})

test_that("plot_prior_predictive plot structure", {
  withr::local_seed(606)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  p <- plot_prior_predictive(sim_data)

  # Check basic plot structure
  expect_true("FacetWrap" %in% class(p$facet))
  expect_equal(p$labels$x, "Time (days)")
  expect_equal(p$labels$title, "Prior Predictive Check")
})
