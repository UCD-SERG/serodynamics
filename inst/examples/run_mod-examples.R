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

  fitted_model <- run_mod(
    data = dataset, # The data set input
    file_mod = serodynamics_example("model.jags"),
    nchain = 4, # Number of mcmc chains to run
    nadapt = 100, # Number of adaptations to run
    nburn = 100, # Number of unrecorded samples before sampling begins
    nmc = 1000,
    niter = 2000, # Number of iterations
    strat = "strat"
  ) # Variable to be stratified
}

# \dontrun{
# This example intentionally triggers the JAGS error:
# "Error in node TauB: Unable to find appropriate sampler"
# It happens when both TauP and TauB are Wishart in the Kronecker prior.

if (!is.element(runjags::findjags(), c("", NULL))) {
  set.seed(109)
  
  # Make tiny fake data with 2 biomarkers so Σ_B is identifiable
  sim <- simulate_multi_b_long(
    n_id      = 3,
    n_blocks  = 2,
    time_grid = c(0, 7, 14),
    sigma_p   = diag(5) * 0.1,
    sigma_b   = diag(2) * 0.2
  )
  
  sim_tbl <- serodynamics::as_case_data(
    sim$data,
    id_var        = "Subject",
    biomarker_var = "antigen_iso",
    value_var     = "value",
    time_in_days  = "time_days"
  )
  
  # Write the Chapter-2 Kronecker model that has *both* TauP and TauB ~ Wishart
  model_path <- write_model_ch2_kron(file.path(tempdir(), 
                                               "model_ch2_kron.jags"))
  
  # This call will fail in JAGS with the 'TauB' sampler error described above
  try(
    fit_kron <- run_mod(
      data          = sim_tbl,
      file_mod      = serodynamics_example("model.jags"), 
      file_mod_kron = model_path,                       # Kronecker model file
      correlated    = TRUE,                             # <-- key switch
      nchain = 2, nadapt = 100, nburn = 50, nmc = 10, niter = 100,
      strat = NA
    )
  )
}
# }
