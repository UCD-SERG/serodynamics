test_that("results are consistent", {
  
  # set.seed(1)
  results <- runjags:::example_runjags()
  results[["mcmc"]] |> 
    ggmcmc::ggs() |> 
    dplyr::filter(Iteration %in% 1:2) |> 
    ssdtools:::expect_snapshot_data(name = "example-head")
})
