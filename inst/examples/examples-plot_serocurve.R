# nepal_sees_jags_output already includes population_params
model <- serodynamics::nepal_sees_jags_output

# Predictive curve for a single antigen-isotype and stratum
p1 <- plot_serocurve(
  model       = model,
  antigen_iso = "HlyE_IgA",
  strat       = "typhi"
)
print(p1)

# Predictive curves for both stratifications, colored by stratum
p2 <- plot_serocurve(
  model       = model,
  antigen_iso = "HlyE_IgA"
)
print(p2)

# Predictive curve faceting by stratification instead of coloring
p3 <- plot_serocurve(
  model          = model,
  antigen_iso    = "HlyE_IgA",
  facet_by_strat = TRUE
)
print(p3)

# Population level curve for multiple antigen-isotypes, faceted, without CI
p4 <- plot_serocurve(
  model                = model,
  antigen_iso          = c("HlyE_IgA", "HlyE_IgG"),
  param_source = "population",
  facet_by_antigen_iso = TRUE,
  show_ci              = FALSE
)
print(p4)

# Population level distribution
p5 <- plot_serocurve(
  model        = model,
  antigen_iso  = "HlyE_IgA",
  param_source = "population"
)
print(p5)
