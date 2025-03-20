
test_that(
  desc = "results are consistent with data frame showing parameter estimates",
  code = {

    data <- serodynamics::nepal_sees_jags_post |>
      suppressWarnings()

    # Testing for any errors:
    results <- post_summ(data) |> expect_no_error()
      
    # Snapshot test to ensure results are consistent:
    testthat::expect_snapshot(results)
  }
)
