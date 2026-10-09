
test_that(
  desc = "results are consistent with checking SEES data",
  code = {
    skip_on_os(c("windows", "linux"))
    withr::local_seed(1)
    dataset <- serodynamics::nepal_sees 
    
    results <- run_mod(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 10, # Number of adaptations to run
      nburn = 10, # Number of unrecorded samples before sampling begins
      nmc = 100,
      niter = 100, # Number of iterations
      strat = "bldculres", # Variable to be stratified
    ) |>
      suppressWarnings()
    
    posterior_test <- posterior_pred(data = results,
                   raw_dat = dataset,
                   n_sim = 5,
                   n_sample = 1000 
                   )
    
    results |>
      attributes() |>
      rlist::list.remove(c("row.names", "fitted_residuals")) |>
      expect_snapshot_value(style = "deparse")
    
    results |>
      expect_snapshot_data("strat-curve-params")
    
    attributes(results)$fitted_residuals |>
      expect_snapshot_data("strat-fitted_residuals")
  }
)
