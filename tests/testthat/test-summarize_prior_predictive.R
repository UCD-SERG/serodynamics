test_that("summarize_prior_predictive basic functionality", {
  withr::local_seed(123)

  # Create test data
  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 3)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  # Single simulation
  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  summary <- summarize_prior_predictive(sim_data)

  expect_s3_class(summary, "prior_predictive_summary")
  expect_type(summary, "list")
  expect_equal(summary$n_sims, 1)
  expect_s3_class(summary$validity_check, "data.frame")
  expect_s3_class(summary$range_summary, "data.frame")
  expect_type(summary$issues, "character")
})

test_that("summarize_prior_predictive with multiple simulations", {
  withr::local_seed(456)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  # Multiple simulations
  n_sims <- 10
  sim_list <- simulate_prior_predictive(
    prepped_data,
    prepped_priors,
    n_sims = n_sims
  )
  summary <- summarize_prior_predictive(sim_list)

  expect_equal(summary$n_sims, n_sims)
  expect_true(nrow(summary$validity_check) > 0)
  expect_true(nrow(summary$range_summary) > 0)
})

test_that("summarize_prior_predictive with observed data comparison", {
  withr::local_seed(789)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 3)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  summary <- summarize_prior_predictive(sim_data, original_data = prepped_data)

  expect_s3_class(summary$observed_range, "data.frame")
  expect_equal(
    nrow(summary$observed_range),
    nrow(summary$range_summary)
  )
  expect_true(
    all(
      c("biomarker", "obs_min", "obs_median", "obs_max") %in%
        names(summary$observed_range)
    )
  )
})

test_that("summarize_prior_predictive validity checks", {
  withr::local_seed(101)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  summary <- summarize_prior_predictive(sim_data)

  # Check validity_check structure
  expect_true(
    all(
      c("biomarker", "n_finite", "n_nonfinite", "n_negative") %in%
        names(summary$validity_check)
    )
  )

  # Check that we have counts for each biomarker
  expect_equal(
    nrow(summary$validity_check),
    prepped_data$n_antigen_isos
  )
})

test_that("summarize_prior_predictive range summary", {
  withr::local_seed(202)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  summary <- summarize_prior_predictive(sim_data)

  # Check range_summary structure
  expect_true(
    all(
      c("biomarker", "min", "q25", "median", "q75", "max") %in%
        names(summary$range_summary)
    )
  )

  # Check that quantiles are ordered (where finite)
  for (i in seq_len(nrow(summary$range_summary))) {
    if (all(is.finite(c(
      summary$range_summary$min[i],
      summary$range_summary$q25[i],
      summary$range_summary$median[i],
      summary$range_summary$q75[i],
      summary$range_summary$max[i]
    )))) {
      expect_true(
        summary$range_summary$min[i] <= summary$range_summary$q25[i]
      )
      expect_true(
        summary$range_summary$q25[i] <= summary$range_summary$median[i]
      )
      expect_true(
        summary$range_summary$median[i] <= summary$range_summary$q75[i]
      )
      expect_true(
        summary$range_summary$q75[i] <= summary$range_summary$max[i]
      )
    }
  }
})

test_that("print method for prior_predictive_summary works", {
  withr::local_seed(303)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
  summary <- summarize_prior_predictive(sim_data)

  # Test that print works without error
  expect_no_error(print(summary))

  # Verify that output is printed (cli headers go to console, not captured)
  # Just check that it doesn't error and returns invisibly
  expect_invisible(print(summary))
})

test_that("summarize_prior_predictive handles invalid inputs gracefully", {
  withr::local_seed(404)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)

  # Test with wrong type of original_data
  expect_warning(
    summarize_prior_predictive(sim_data, original_data = list(a = 1)),
    "is not a.*prepped_jags_data"
  )
})

test_that("summarize_prior_predictive result consistency", {
  withr::local_seed(505)

  raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 2)
  prepped_data <- prep_data(raw_data)
  prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

  sim_list <- simulate_prior_predictive(
    prepped_data,
    prepped_priors,
    n_sims = 3
  )
  summary <- summarize_prior_predictive(sim_list, original_data = prepped_data)

  # Snapshot key parts of the summary
  expect_snapshot_value(
    list(
      n_sims = summary$n_sims,
      validity_check_cols = names(summary$validity_check),
      range_summary_cols = names(summary$range_summary),
      has_observed_range = !is.null(summary$observed_range),
      n_issues = length(summary$issues)
    ),
    style = "deparse"
  )
})
