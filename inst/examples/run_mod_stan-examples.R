if (requireNamespace("cmdstanr", quietly = TRUE)) {
  library(dplyr)
  set.seed(1)
  strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 100) |>
    mutate(strat = "stratum 2")
  strat2 <- serocalculator::typhoid_curves_nostrat_100 |>
    sim_case_data(n = 100) |>
    mutate(strat = "stratum 1")

  dataset <- bind_rows(strat1, strat2)

  fitted_model <- run_mod_stan(
    data = dataset, # The data set input
    file_mod = serodynamics_example("model.stan"),
    nchain = 4, # Number of mcmc chains to run
    nadapt = 500, # Number of warmup iterations
    niter = 1000, # Number of sampling iterations
    strat = "strat" # Variable to be stratified
  )
}
