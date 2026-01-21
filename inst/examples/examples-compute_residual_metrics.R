sees_model <- serodynamics::nepal_sees_jags_output
sees_data <- serodynamics::nepal_sees

# Example 1: Pointwise residuals for a single ID
pointwise_resid <- compute_residual_metrics(
  model = sees_model,
  dataset = sees_data,
  ids = "sees_npl_128",
  antigen_iso = "HlyE_IgA",
  scale = "original",
  summary_level = "pointwise"
)
print(pointwise_resid)

# Example 2: Summary metrics per ID × antigen_iso (default)
summary_per_id <- compute_residual_metrics(
  model = sees_model,
  dataset = sees_data,
  ids = "sees_npl_128",
  antigen_iso = "HlyE_IgA",
  scale = "original"
)
print(summary_per_id)

# Example 3: Multiple IDs with summary per ID
multi_id_summary <- compute_residual_metrics(
  model = sees_model,
  dataset = sees_data,
  ids = c("sees_npl_128", "sees_npl_131"),
  antigen_iso = "HlyE_IgA",
  scale = "original",
  summary_level = "id_antigen"
)
print(multi_id_summary)

# Example 4: Overall summary across multiple IDs
overall_summary <- compute_residual_metrics(
  model = sees_model,
  dataset = sees_data,
  ids = c("sees_npl_128", "sees_npl_131"),
  antigen_iso = "HlyE_IgA",
  scale = "original",
  summary_level = "overall"
)
print(overall_summary)

# Example 5: Log-scale residuals
log_resid <- compute_residual_metrics(
  model = sees_model,
  dataset = sees_data,
  ids = "sees_npl_128",
  antigen_iso = "HlyE_IgA",
  scale = "log",
  summary_level = "id_antigen"
)
print(log_resid)
