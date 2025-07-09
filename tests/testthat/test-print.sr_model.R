test_that(
  desc = "results are consistent with printed output for sr_model class",
  code = {
    withr::local_seed(1)
    results <- print(nepal_sees_jags_output) |>
          ssdtools:::expect_snapshot_data("default-print-runmod-object")
        
  }
)
