dataset <- serodynamics::nepal_sees 

nepal_sees_jags_output <- run_mod(
  data = dataset, # The data set input
  file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
  nchain = 2, # Number of mcmc chains to run
  nadapt = 100, # Number of adaptations to run
  nburn = 100, # Number of unrecorded samples before sampling begins
  nmc = 500,
  niter = 1000, # Number of iterations
  strat = "bldculres", # Stratification
  post_
  include_subs = TRUE
)

# Filtering to keep only 2 subjects + newperson


usethis::use_data(nepal_sees_jags_output, overwrite = TRUE)
