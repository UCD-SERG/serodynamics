test_that(
  desc = "results are consistent with printed output for sr_model class",
  code = {
    testthat::expect_snapshot(nepal_sees_jags_output) 
  }
)

test_that(
  desc = "results are consistent with printed output for sr_model class as tbl",
  code = {
    testthat::expect_snapshot(print(nepal_sees_jags_output, print_tbl = TRUE)) 
  }
)

test_that(
  desc = "results are consistent with printed output for sr_model class as tbl
  with no stratification",
  code = {
    dataset <- serodynamics::nepal_sees
    results <- run_mod(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 10, # Number of adaptations to run
      nburn = 10, # Number of unrecorded samples before sampling begins
      nmc = 100,
      niter = 100, # Number of iterations
    ) |>
      suppressWarnings()

    testthat::expect_snapshot(print(results)) 
  }
)
