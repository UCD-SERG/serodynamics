test_that("results are consistent", {
  
  # set.seed(1)
  results <- runjags:::example_runjags()
  results |> plot(vars = "c", plot.type = "trace")
  results[["mcmc"]] |> 
    ggmcmc::ggs() |> 
    dplyr::filter(Iteration %in% 1:2) |> 
    ssdtools:::expect_snapshot_data(name = "example-head")
})


test_that("results are consistent with our model", {
  
  set.seed(1)
  strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 9, antigen_isos = "HlyE_IgA") |>
    mutate(strat = "stratum 2")
  longdata <- prep_data(strat1, add_newperson = FALSE)
  priors <- prep_priors(max_antigens = longdata$n_antigen_isos)
  
  tomonitor <- c("y0", "y1", "t1", "alpha", "shape")
  set.seed(1)
  jags_post <- runjags::run.jags(
    model = serodynamics_example("model.jags"),
    data = c(longdata, priors),
    inits = initsfunction,
    method = "rjags",
    adapt = 1000,
    burnin = 0,
    thin = 1,
    sample = 100,
    n.chains = 2,
    monitor = tomonitor,
    summarise = TRUE
  ) |> 
    suppressWarnings()
  plot(jags_post, 
       layout = c(3,2),
       vars = c("y0[1,1]", "y1[1,1]", "t1[1,1]", "alpha[1,1]", "shape[1,1]"), 
       plot.type = "trace")
  samples <- jags_post[["mcmc"]] |> 
    ggmcmc::ggs() |> 
    dplyr::filter(Iteration %in% 1:2) |> 
    print()
  
  samples |> 
    ssdtools:::expect_snapshot_data(name = "kinetics")
  
})
