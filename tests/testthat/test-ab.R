test_that("results are consistent", {
  params <- 
    serocalculator::typhoid_curves_nostrat_100 |> 
    head(2)
  
  params |> 
    dplyr::select(-c(antigen_iso, iter)) |> 
    dplyr::rename(shape = r) |> 
    dplyr::mutate(t = 10) |> 
    do.call(what = ab) |> 
    expect_snapshot()
})

test_that("exponential decay branch is consistent", {
  expect_equal(
    ab(
      t = c(0, 2, 4),
      y0 = 1,
      y1 = 10,
      t1 = 2,
      alpha = 0.5,
      shape = 2,
      decay_type = "exponential"
    ),
    c(1, 10, 10 * exp(-1))
  )
})
