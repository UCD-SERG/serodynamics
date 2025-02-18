test_that("results are consistent", {
  initsfunction(c(4, 1, 3, 2)) |> expect_snapshot_value(style = "deparse")
})
