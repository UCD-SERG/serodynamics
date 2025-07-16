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

# 3) Load the pre-computed model output included with the package.
# This is much faster than running the model live.
model <- serodynamics::nepal_sees_jags_output


# 4a) Plot (linear axes) with all individual curves + median ribbon
p1 <- plot_predicted_curve(
  sr_model           = model,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  dataset            = dat,
  legend_obs         = "Observed data",
  legend_median        = "Median prediction",
  show_quantiles     = TRUE,
  log_y          = FALSE,
  log_x              = FALSE,
  show_all_curves    = TRUE
)
print(p1)

# 4b) Plot (log10 y-axis) with all individual curves + median ribbon
p2 <- plot_predicted_curve(
  sr_model           = model,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  dataset            = dat,
  legend_obs         = "Observed data",
  legend_median        = "Median prediction",
  show_quantiles     = TRUE,
  log_y          = TRUE,
  log_x              = FALSE,
  show_all_curves    = TRUE
)
print(p2)

# 4c) Plot with custom x-axis limits (0-600 days)
p3 <- plot_predicted_curve(
  sr_model           = model,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  dataset            = dat,
  legend_obs         = "Observed data",
  legend_median        = "Median prediction",
  show_quantiles     = TRUE,
  log_y          = FALSE,
  log_x              = FALSE,
  show_all_curves    = TRUE,
  xlim               = c(0, 600)
)
print(p3)
