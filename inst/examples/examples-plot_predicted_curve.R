sees_model <- serodynamics::nepal_sees_jags_output
sees_data <- serodynamics::nepal_sees

# Plot (linear axes) with all individual curves + median ribbon
p1 <- plot_predicted_curve(
  model              = sees_model,
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
  model              = sees_model,
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
  model              = sees_model,
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
  model           = sees_model,
  dataset         = sees_data,
  id              = c("sees_npl_128", "sees_npl_131"),
  antigen_iso     = "HlyE_IgA",
  show_all_curves = TRUE,
  facet_by_id     = TRUE
)
print(p4)

# Example with assay-specific Y-axis labels:
# Using ELISA_OD assay type
p5 <- plot_predicted_curve(
  model              = sees_model,
  dataset            = sees_data,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  show_quantiles     = TRUE,
  log_y              = FALSE,
  show_all_curves    = FALSE,
  assay              = "ELISA_OD"
)
print(p5)

# Using Kinetic_ELISA assay type with log scale
p6 <- plot_predicted_curve(
  model              = sees_model,
  dataset            = sees_data,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  show_quantiles     = TRUE,
  log_y              = TRUE,
  show_all_curves    = FALSE,
  assay              = "Kinetic_ELISA"
)
print(p6)

# Using multiplex-bg assay type
p7 <- plot_predicted_curve(
  model              = sees_model,
  dataset            = sees_data,
  id                 = "sees_npl_128",
  antigen_iso        = "HlyE_IgA",
  show_quantiles     = TRUE,
  log_y              = FALSE,
  show_all_curves    = FALSE,
  assay              = "multiplex-bg"
)
print(p7)
