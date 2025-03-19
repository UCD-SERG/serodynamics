test_that("results are consistent", {
  
  # set.seed(1)
  results <- runjags:::example_runjags()
  results[["mcmc"]] |> 
    ggmcmc::ggs() |> 
    dplyr::filter(Iteration %in% 1:2) |> 
    ssdtools:::expect_snapshot_data(name = "example-head")
})


test_that("results are consistent with our model", {
  
  library(runjags)
  set.seed(1)
  library(dplyr)
  strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 20, antigen_isos = "HlyE_IgA") |>
    mutate(strat = "stratum 2")
  longdata <- prep_data(strat1, add_newperson = FALSE)
  priors <- prep_priors(max_antigens = longdata$n_antigen_isos)
  
  tomonitor <- c("y0", "y1", "t1", "alpha", "shape")
  
  jags_post <- runjags::run.jags(
    model = serodynamics_example("model.jags"),
    data = c(longdata, priors),
    inits = initsfunction,
    method = "simple",
    adapt = 50,
    burnin = 1,
    thin = 1,
    sample = 2,
    n.chains = 1,
    monitor = tomonitor,
    summarise = FALSE
  ) |> 
    suppressWarnings()
  
  samples <- jags_post[["mcmc"]] |> 
    ggmcmc::ggs() |> 
    dplyr::filter(Iteration %in% 1:2) |> 
    print()
  
  samples |> 
    ssdtools:::expect_snapshot_data(name = "kinetics")
  
})
