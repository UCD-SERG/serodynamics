test_that(
  desc = "results are consistent with printed output for sr_model class",
  code = {
    nepal_sees_jags_output |>
      suppressWarnings() |>
      expect_snapshot() 
  }
)
