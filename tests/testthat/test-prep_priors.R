test_that("results are consistent", {
  prep_priors(max_antigens = 2) |> 
    expect_snapshot_value(style = "deparse")
})
