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
  with_post     = TRUE
)

# Filter the model's curve parameters to only include the data needed
# for the test case. This dramatically reduces the size of the output file.
model <- model |>
  dplyr::filter(
    .data$Subject == "sees_npl_128",
    .data$Iso_type == "HlyE_IgA"
  )

# 4. Save output to disk for reproducibility or testing
list(
  dat = dat,
  model = model
) |>
  readr::write_rds(file = "tests/testthat/fixtures/example_runmod_output.rds")
