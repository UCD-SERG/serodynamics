sees_model <- serodynamics::nepal_sees_jags_output
sees_data <- serodynamics::nepal_sees

# Plot (linear axes) with all individual curves + median ribbon
p1 <- plot_predicted_curve(
  sr_model           = sees_model,
  dataset            = sees_data,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  show_quantiles     = TRUE,
  log_y              = FALSE,
  log_x              = FALSE,
  show_all_curves    = TRUE
)
print(p1)

# Plot (log10 y-axis) with all individual curves + median ribbon
p2 <- plot_predicted_curve(
  sr_model           = sees_model,
  dataset            = sees_data,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  show_quantiles     = TRUE,
  log_y              = TRUE,
  log_x              = FALSE,
  show_all_curves    = TRUE
)
print(p2)

# Plot with custom x-axis limits (0-600 days)
p3 <- plot_predicted_curve(
  sr_model           = sees_model,
  dataset            = sees_data,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  show_quantiles     = TRUE,
  log_y              = FALSE,
  log_x              = FALSE,
  show_all_curves    = TRUE,
  xlim               = c(0, 600)
)
print(p3)

# Multi-ID, faceted plot (single antigen):
p4 <- plot_predicted_curve(
  sr_model           = sees_model,
  dataset            = sees_data,
  id              = c("sees_npl_128", "sees_npl_131"),
  antigen_iso     = "HlyE_IgA",
  show_all_curves = TRUE,
  facet_by_id     = TRUE
)
print(p4)
