# 1. Build the full dataset from the serodynamics package
dataset <- serodynamics::nepal_sees |>
  as_case_data(
    id_var        = "id",
    biomarker_var = "antigen_iso",
    value_var     = "value",
    time_in_days  = "timeindays"
  ) |>
  dplyr::rename(
    strat       = bldculres,
    timeindays  = dayssincefeveronset,
    value       = result
  )

# 2. Extract specific subject-antigen data for plotting or inspection
dat <- dataset |>
  dplyr::filter(
    id          == "sees_npl_128",
    antigen_iso == "HlyE_IgA"
  )

# 3. Fit the Bayesian model using serodynamics::run_mod()
model <- run_mod(
  data          = dataset,
  file_mod      = serodynamics_example("model.jags"),
  nchain        = 2,
  nadapt        = 100,
  nburn         = 100,
  nmc           = 500,
  niter         = 1000,
  strat         = "strat",
  include_subs  = TRUE
)

# 4. Extract MCMC samples for specific subject + antigen combination
devtools::load_all()

full_samples <- process_jags_samples(
  jags_post   = model,
  dataset     = dataset,
  id          = "sees_npl_128",
  antigen_iso = "HlyE_IgA"
)

# 5. Save output to disk for reproducibility or testing
full_samples |>
  structure(
    ids           = attr(dataset, "ids"),
    antigen_isos  = attr(dataset, "antigens")
  ) |>
  readr::write_rds(file = "tests/testthat/fixtures/example_runmod_output.rds")
