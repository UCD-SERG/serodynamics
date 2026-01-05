test_that(
  desc = "results are consistent with simulated data",
  code = {
    testthat::announce_snapshot_file("sim-strat-curve-params.csv")
    testthat::announce_snapshot_file("sim-strat-fitted_residuals.csv")
    withr::local_seed(1)
    strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
      sim_case_data(n = 100,
                    antigen_isos = "HlyE_IgA") |>
      mutate(strat = "stratum 2")
    withr::local_seed(2)
    strat2 <- serocalculator::typhoid_curves_nostrat_100 |>
      sim_case_data(n = 100, antigen_isos = "HlyE_IgA") |>
      mutate(strat = "stratum 1")
    dataset <- dplyr::bind_rows(strat1, strat2)
    results <- run_mod(
      data = dataset, # The data set input
      file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 100, # Number of adaptations to run
      nburn = 100, # Number of unrecorded samples before sampling begins
      nmc = 10,
      niter = 10, # Number of iterations
      strat = "strat", # Variable to be stratified
    ) |>
      suppressWarnings()
    
    
    results |>
      attributes() |>
      rlist::list.remove(c("row.names", "fitted_residuals")) |>
      expect_snapshot_value(style = "deparse")
    
    results |>
      expect_snapshot_data("sim-strat-curve-params", variant = system_os())
    
    attributes(results)$fitted_residuals |>
      expect_snapshot_data("sim-strat-fitted_residuals", variant = system_os())
    
  }
)

test_that(
  desc = "results are consistent with SEES data",
  code = {
    testthat::announce_snapshot_file("strat-curve-params.csv")
    testthat::announce_snapshot_file("strat-fitted_residuals.csv")
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
    
    results |>
      attributes() |>
      rlist::list.remove(c("row.names", "fitted_residuals")) |>
      expect_snapshot_value(style = "deparse")
    
    results |>
      expect_snapshot_data("strat-curve-params", variant = system_os())
    
    attributes(results)$fitted_residuals |>
      expect_snapshot_data("strat-fitted_residuals", variant = system_os())
  }
)

test_that(
  desc = "results are consistent with unstratified SEES data",
  code = {
    announce_snapshot_file("nostrat-curve-params.csv")
    announce_snapshot_file("nostrat-fitted_residuals.csv")
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
      strat = NA, # Variable to be stratified
    ) |>
      suppressWarnings()
    
    results |>
      attributes() |>
      rlist::list.remove(c("row.names", "fitted_residuals")) |>
      expect_snapshot_value(style = "deparse")
    
    results |>
      expect_snapshot_data("nostrat-curve-params", variant = system_os())
    
    attributes(results)$fitted_residuals |>
      expect_snapshot_data("nostrat-fitted_residuals", variant = system_os())
  }
)

test_that(
  desc = "results are consistent with unstratified SEES data with jags.post
  included",
  code = {
    announce_snapshot_file("nostrat-curve-params-withpost.csv")
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
      strat = NA, # Variable to be stratified
      with_post = TRUE
    ) |>
      suppressWarnings()
    
    results |>
      attributes() |>
      rlist::list.remove(c("row.names", "jags.post", "fitted_residuals")) |>
      expect_snapshot_value(style = "serialize")
    
    results |>
      expect_snapshot_data("nostrat-curve-params-withpost")
  }
)

test_that(
  desc = "results are consistent with unstratified SEES data with modified 
  priors",
  code = {
    announce_snapshot_file("nostrat-curve-params-specpriors.csv")
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
      strat = NA, # Variable to be stratified
      mu_hyp_param = c(1, 4, 1, -3, -1),
      prec_hyp_param = c(0.01, 0.0001, 0.01, 0.001, 0.01),
      omega_param = c(1, 20, 1, 10, 1),
      wishdf_param = 10,
      prec_logy_hyp_param = c(3, 1)
    ) |>
      suppressWarnings()
    
    results |>
      attributes() |>
      rlist::list.remove(c("row.names", "fitted_residuals")) |>
      expect_snapshot_value(style = "serialize")
    
    results |>
      expect_snapshot_data("nostrat-curve-params-specpriors")
  }
)
