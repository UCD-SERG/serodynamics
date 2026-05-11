# Tests for Stan backend functions
# These tests validate prep_data_stan(), prep_priors_stan(), and run_mod_stan()

test_that("prep_priors_stan results are consistent", {
  prep_priors_stan(max_antigens = 2) |>
    expect_snapshot_value(style = "deparse")
})

test_that("prep_priors_stan priors are modifiable", {
  prep_priors_stan(
    max_antigens = 2,
    mu_hyp_param = c(1.0, 5.0, 0.0, -2.0, -3.0),
    prec_hyp_param = c(0.01, 0.01, 0.01, 0.01, 0.01),
    omega_param = c(1.0, 50.0, 1.0, 5.0, 1.0),
    wishdf_param = 15,
    prec_logy_hyp_param = c(4.0, 1.0)
  ) |>
    expect_snapshot_value(style = "deparse")
})

test_that("prep_data_stan validates NA values in input data", {
  # Create data with NA values
  case_data_with_na <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 10, antigen_isos = "HlyE_IgA")
  
  # Introduce NA in value column
  case_data_with_na$value[1] <- NA
  
  expect_error(
    suppressWarnings(prep_data_stan(case_data_with_na)),
    "Stan data cannot contain NA values"
  )
})

test_that("prep_data_stan results are consistent", {
  withr::local_seed(1)
  case_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 20, antigen_isos = "HlyE_IgA")
  
  prepped_data <- suppressWarnings(prep_data_stan(case_data))
  
  # Check structure
  expect_type(prepped_data, "list")
  expect_true(
    all(c("nsubj", "n_antigen_isos", "n_params", "nsmpl",
          "max_nsmpl", "smpl_t", "logy") %in% names(prepped_data))
  )
  
  # Check that data is padded (rectangular arrays)
  expect_equal(length(dim(prepped_data$logy)), 3)
  expect_equal(length(dim(prepped_data$smpl_t)), 2)
  
  # Snapshot the structure
  prepped_data |> expect_snapshot_value(style = "serialize")
})

test_that("run_mod_stan errors when cmdstanr not available", {
  skip_if(requireNamespace("cmdstanr", quietly = TRUE),
          "cmdstanr is available, skipping unavailability test")
  
  case_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 10, antigen_isos = "HlyE_IgA")
  
  expect_error(
    run_mod_stan(case_data),
    "cmdstanr"
  )
})

test_that("run_mod_stan works with cmdstanr installed", {
  skip_if_not_installed("cmdstanr")
  skip_if(
    is.null(tryCatch(cmdstanr::cmdstan_version(), error = function(e) NULL)),
    "CmdStan not installed"
  )
  
  withr::local_seed(1)
  case_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 20, antigen_isos = "HlyE_IgA")
  
  results <- run_mod_stan(
    data = case_data,
    file_mod = serodynamics_example("model.stan"),
    nchain = 2,
    nadapt = 100,
    niter = 10
  ) |>
    suppressWarnings()
  
  # Check output structure
  expect_s3_class(results, "sr_model")
  expect_s3_class(results, "tbl_df")
  
  # Check required columns
  expect_true(
    all(c("Parameter", "value", "Stratification") %in% names(results))
  )
  
  # Check attributes
  attrs <- attributes(results)
  expect_true("priors" %in% names(attrs))
  expect_true("fitted_residuals" %in% names(attrs))
  
  # Snapshot attributes (excluding row.names and fitted_residuals for stability)
  attrs |>
    rlist::list.remove(c("row.names", "fitted_residuals")) |>
    expect_snapshot_value(style = "deparse")
})

test_that("run_mod_stan works with stratification", {
  skip_if_not_installed("cmdstanr")
  skip_if(
    is.null(tryCatch(cmdstanr::cmdstan_version(), error = function(e) NULL)),
    "CmdStan not installed"
  )
  
  withr::local_seed(1)
  strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 20, antigen_isos = "HlyE_IgA") |>
    dplyr::mutate(strat = "stratum 1")
  
  withr::local_seed(2)
  strat2 <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 20, antigen_isos = "HlyE_IgA") |>
    dplyr::mutate(strat = "stratum 2")
  
  dataset <- dplyr::bind_rows(strat1, strat2)
  
  results <- run_mod_stan(
    data = dataset,
    file_mod = serodynamics_example("model.stan"),
    nchain = 2,
    nadapt = 100,
    niter = 10,
    strat = "strat"
  ) |>
    suppressWarnings()
  
  # Check stratification column exists and has correct values
  expect_true("Stratification" %in% names(results))
  expect_true(all(c("stratum 1", "stratum 2") %in% results$Stratification))
  
  # Check that both strata have results
  strat_counts <- table(results$Stratification)
  expect_equal(length(strat_counts), 2)
  expect_true(all(strat_counts > 0))
})

test_that("sample_predictive_stan works with fitted Stan model", {
  skip_if_not_installed("cmdstanr")
  skip_if(
    is.null(tryCatch(cmdstanr::cmdstan_version(), error = function(e) NULL)),
    "CmdStan not installed"
  )
  
  withr::local_seed(1)
  case_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 20, antigen_isos = "HlyE_IgA")
  
  # Fit model with posterior samples
  model_output <- run_mod_stan(
    data = case_data,
    file_mod = serodynamics_example("model.stan"),
    nchain = 2,
    nadapt = 100,
    niter = 10,
    with_post = TRUE
  ) |>
    suppressWarnings()
  
  # Generate predictions
  predictions <- sample_predictive_stan(
    model_output,
    time_points = c(5, 30, 90),
    n_samples = 10
  )
  
  # Check structure
  expect_s3_class(predictions, "posterior_predictive_stan")
  expect_type(predictions, "list")
  expect_true(all(c("samples", "time_points", "summary") %in% names(predictions)))
  
  # Check samples array dimensions
  # 10 samples, 3 timepoints, 1 antigen
  expect_equal(dim(predictions$samples), c(10, 3, 1))
  
  # Check time points
  expect_equal(predictions$time_points, c(5, 30, 90))
  
  # Check summary structure
  expect_type(predictions$summary, "list")
  # 1 antigen
  expect_equal(length(predictions$summary), 1)
  expect_true("HlyE_IgA" %in% names(predictions$summary))
  
  # Check summary data frame
  summary_df <- predictions$summary$HlyE_IgA
  expect_s3_class(summary_df, "data.frame")
  # 3 timepoints
  expect_equal(nrow(summary_df), 3)
  expect_true(
    all(
      c("time_point", "mean", "median", "lower_95", "upper_95") %in%
        names(summary_df)
    )
  )
})

test_that("sample_predictive_stan errors without posterior samples", {
  skip_if_not_installed("cmdstanr")
  skip_if(
    is.null(tryCatch(cmdstanr::cmdstan_version(), error = function(e) NULL)),
    "CmdStan not installed"
  )
  
  withr::local_seed(1)
  case_data <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 20, antigen_isos = "HlyE_IgA")
  
  # Fit model WITHOUT posterior samples
  model_output <- run_mod_stan(
    data = case_data,
    file_mod = serodynamics_example("model.stan"),
    nchain = 2,
    nadapt = 100,
    niter = 10,
    with_post = FALSE
  ) |>
    suppressWarnings()
  
  # Should error when trying to generate predictions
  expect_error(
    sample_predictive_stan(model_output),
    "Posterior samples not found"
  )
})
