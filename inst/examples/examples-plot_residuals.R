plot_residuals(
  model = serodynamics::nepal_sees_jags_output,
  dataset = serodynamics::nepal_sees,
  ids = c("sees_npl_128", "sees_npl_131"),
  antigen_isos = c("HlyE_IgA", "HlyE_IgG"),
  n_draws = 100
)

