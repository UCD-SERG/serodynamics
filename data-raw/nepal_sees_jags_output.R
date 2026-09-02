dataset <- serodynamics::nepal_sees

set.seed(42)
nepal_sees_jags_output <- run_serodynamics(
  data = dataset, # The data set input
  file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
  nchain = 2, # Number of mcmc chains to run
  nadapt = 100, # Number of adaptations to run
  nburn = 100, # Number of unrecorded samples before sampling begins
  nmc = 500,
  niter = 1000, # Number of iterations
  strat = "bldculres", # Stratification
  mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
  prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
  omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
  wishdf_param = 20,
  prec_logy_hyp_param = c(4.0, 1.0),
  with_post = FALSE,
  with_pop_params = TRUE
)

# Filtering to keep only 2 subjects + newperson + all subjects with visit_num 5
subjects_v5 <- unique(dataset$id[dataset$visit_num == 5])
keep_subjects <- unique(c("newperson", "sees_npl_1", "sees_npl_2", subjects_v5))
nepal_sees_jags_output <- nepal_sees_jags_output |>
  filter(Subject %in% keep_subjects)

usethis::use_data(nepal_sees_jags_output, overwrite = TRUE)
