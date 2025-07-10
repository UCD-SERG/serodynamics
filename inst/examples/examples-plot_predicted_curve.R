# 1) Prepare the on-the-fly dataset
dataset <- serodynamics::nepal_sees |>
  as_case_data(
    id_var        = "id",
    biomarker_var = "antigen_iso",
    value_var     = "value",
    time_in_days  = "timeindays"
  ) |>
  dplyr::rename(
    strat      = bldculres,
    timeindays = dayssincefeveronset,
    value      = result
  )

# 2) Extract just the one subject/antigen for overlay later
dat <- dataset |>
  dplyr::filter(id == "sees_npl_128", antigen_iso == "HlyE_IgA")

# 3) Fit the model to the full dataset
model <- run_mod(
  data         = dataset,
  file_mod     = serodynamics_example("model.jags"),
  nchain       = 2,
  nadapt       = 100,
  nburn        = 100,
  nmc          = 500,
  niter        = 1000,
  strat        = "strat"
)

# 4a) Plot (linear axes) with all individual curves + median ribbon
p1 <- plot_predicted_curve(
  jags_post          = model,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  dataset            = dat,
  legend_obs         = "Observed Data",
  legend_mod1        = "Median Prediction",
  show_quantiles     = TRUE,
  log_scale          = FALSE,
  log_x              = FALSE,
  show_all_curves    = TRUE
)
print(p1)

# 4b) Plot (log10 y-axis) with all individual curves + median ribbon
p2 <- plot_predicted_curve(
  jags_post          = model,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  dataset            = dat,
  legend_obs         = "Observed Data",
  legend_mod1        = "Median Prediction",
  show_quantiles     = TRUE,
  log_scale          = TRUE,
  log_x              = FALSE,
  show_all_curves    = TRUE
)
print(p2)

# 4c) Plot with custom x-axis limits (0-600 days)
p3 <- plot_predicted_curve(
  jags_post          = model,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  dataset            = dat,
  legend_obs         = "Observed Data",
  legend_mod1        = "Median Prediction",
  show_quantiles     = TRUE,
  log_scale          = FALSE,
  log_x              = FALSE,
  show_all_curves    = TRUE,
  xlim               = c(0, 600)
)
print(p3) 