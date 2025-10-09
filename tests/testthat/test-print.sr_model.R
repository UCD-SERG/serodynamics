test_that(
  desc = "results are consistent with printed output for sr_model class",
  code = {
    results <- print(nepal_sees_jags_output)
    results |>
    testthat::expect_snapshot("as summary") 
  }
)

test_that(
  desc = "results are consistent with printed output for sr_model class 
  as a tbl",
  code = {
    results <- print(nepal_sees_jags_output, print_tbl = TRUE)
    results |>
    testthat::expect_snapshot_data("as tbl") 
  }
)
