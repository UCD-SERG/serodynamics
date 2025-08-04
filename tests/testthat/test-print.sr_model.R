test_that(
  desc = "results are consistent with printed output for sr_model class",
  code = {
    expect_snapshot(nepal_sees_jags_output)
  }
)
