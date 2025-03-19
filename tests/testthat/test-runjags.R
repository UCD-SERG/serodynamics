test_that("results are consistent", {
  
  # set.seed(1)
  results <- runjags:::example_runjags(sample = 100)
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
  # longdata <- prep_data(strat1, add_newperson = FALSE)
  longdata <- 
    readr::read_rds(
      testthat::test_path("fixtures", "example_runjags_inputs.rds")
    )
  priors <- prep_priors(max_antigens = longdata$n_antigen_isos)
  
  tomonitor <- c("y0", "y1", "t1", "alpha", "shape")
  set.seed(1)
  jags_post <- runjags::run.jags(
    model = serodynamics_example("model.jags"),
    data = c(longdata, priors),
    inits = initsfunction,
    method = "rjags",
    adapt = 0,
    burnin = 0,
    thin = 1,
    sample = 100,
    n.chains = 1,
    monitor = tomonitor,
    summarise = TRUE
  ) |> 
    suppressWarnings()
  
  jags_post$end.state |> 
    as.character() |> 
    stringr::str_split(pattern = "\n") |> 
    unlist() |> 
    head(1) |> 
    expect_snapshot()
  
  plot(jags_post, 
       layout = c(5,2),
       vars = c("y0[1,1]", "y1[1,1]", "t1[1,1]", "alpha[1,1]", "shape[1,1]",
                "y0[3,1]", "y1[3,1]", "t1[3,1]", "alpha[3,1]", "shape[3,1]"),  
       plot.type = "trace")
  
  samples <- jags_post[["mcmc"]] |> 
    ggmcmc::ggs() |> 
    print()
  
  samples |> 
    dplyr::arrange(Iteration) |> 
    # dplyr::filter(Iteration %in% c(1, 2, max(Iteration))) |> 
    ssdtools:::expect_snapshot_data(name = "kinetics")
  
  # running this on posit cloud (linux), the first discrepancy 
  # occurs at iteration 19, when person 6's model changes.
  # windows and mac agree when adapt = 0, but when adapt = 1000,
  # all three operating systems differ, even though jags_post$end.state[".RNG.state"]) matches
  
})
