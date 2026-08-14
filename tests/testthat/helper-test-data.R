
# Unstratified run_serodynamics
withr::local_seed(1)
dataset <- serodynamics::nepal_sees

results_unstrat_exp <- run_serodynamics(
  data = dataset, # The data set input
  file_mod = serodynamics_example("model.jags"),
  decay_type = "exponential",
  nchain = 2, # Number of mcmc chains to run
  nadapt = 10, # Number of adaptations to run
  nburn = 10, # Number of unrecorded samples before sampling begins
  nmc = 100,
  niter = 100, # Number of iterations
  strat = NA, # Variable to be stratified
  with_post = TRUE,
  mu_hyp_param = c(1, 4, 1, -3, -1),
  prec_hyp_param = c(0.01, 0.0001, 0.01, 0.001, 0.01),
  omega_param = c(1, 20, 1, 10, 1),
  wishdf_param = 10,
  prec_logy_hyp_param = c(3, 1)
) |>
  suppressWarnings()
