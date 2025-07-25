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
