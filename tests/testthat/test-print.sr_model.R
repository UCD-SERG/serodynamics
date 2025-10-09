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

