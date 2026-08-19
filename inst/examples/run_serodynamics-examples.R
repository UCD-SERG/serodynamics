if (!is.element(runjags::findjags(), c("", NULL))) {
  library(runjags)
  set.seed(1)
  library(dplyr)
  strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 100) |>
    mutate(strat = "stratum 2")
  strat2 <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 100) |>
    mutate(strat = "stratum 1")

  dataset <- bind_rows(strat1, strat2)

  fitted_model <- run_serodynamics(
    data = dataset, # The data set input
    file_mod = serodynamics_example("model.jags"),
    nchain = 4, # Number of mcmc chains to run
    nadapt = 100, # Number of adaptations to run
    nburn = 100, # Number of unrecorded samples before sampling begins
    nmc = 1000,
    niter = 2000, # Number of iterations
    strat = "strat",
    mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
    prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
    omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
    wishdf_param = 20,
    prec_logy_hyp_param = c(4.0, 1.0)
  ) # Variable to be stratified
}
