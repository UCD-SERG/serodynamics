# Smoke tests: verify the Model 2a pipeline RUNS end to end and returns the
# expected structure, at tiny MCMC scale (matching test-run_mod.R's CI norm).
# Accurate parameter recovery / the Chapter-1 comparison are science checks run
# locally at full length (see validate_recovery_2a(), compare_mod_2a()), not in
# routine CI.

skip_if_no_jags <- function() {
  testthat::skip_if_not_installed("runjags")
  jags <- tryCatch(runjags::findjags(), error = function(e) "")
  if (is.null(jags) || identical(jags, "")) testthat::skip("JAGS not found")
}

tiny_two_biomarker_data <- function(n = 15) {
  sim_case_data_2a(
    n = n,
    mu_g = c(0, 3, 2.3, -4, -1), mu_a = c(0.2, 3.1, 2.2, -3.8, -1.1),
    sigma_g = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
    sigma_a = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
    c_vec = c(0.05, 0.08, 0, 0.06, 0),
    visit_times = c(0, 14, 30, 90, 180),
    seed = 1
  )$data
}

test_that("run_mod_2a runs and returns a cross-biomarker summary", {
  skip_if_no_jags()
  skip_on_cran()
  
  fit <- run_mod_2a(
    tiny_two_biomarker_data(),
    nchain = 2, nadapt = 10, nburn = 10, nmc = 100, niter = 100
  ) |> suppressWarnings()
  
  expect_s3_class(fit, "model_2a_fit")
  expect_s3_class(fit$mcmc, "mcmc.list")
  expect_equal(nrow(fit$cross), 5)                    # one row per parameter
  expect_true(all(c("param", "cov_med", "cor_med", "cov_lo", "cov_hi")
                  %in% names(fit$cross)))
})

test_that("compare_mod_2a runs both models and returns the shared comparison", {
  skip_if_no_jags()
  skip_on_cran()
  
  cmp <- compare_mod_2a(
    tiny_two_biomarker_data(),
    nchain = 2, nadapt = 10, nburn = 10, nmc = 100, niter = 100
  ) |> suppressWarnings()
  
  expect_s3_class(cmp, "model_2a_comparison")
  expect_equal(nrow(cmp$shared), 10)                  # 2 biomarkers x 5 params
  expect_true(all(c("mean_med_ch1", "mean_med_2a", "mean_absdiff",
                    "var_med_ch1", "var_med_2a", "var_absdiff")
                  %in% names(cmp$shared)))
  expect_equal(nrow(cmp$cross), 5)                    # Model 2a's addition
  expect_length(cmp$max_mean_absdiff, 1)
  expect_type(cmp$added, "character")
})
