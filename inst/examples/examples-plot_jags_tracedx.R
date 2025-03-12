
  data <- serodynamics::nepal_sees_jags_post

  # Specifying isotype, parameter, and stratification for traceplot.
  plot_jags_trace(
                  data = data,
                  iso = "HlyE_IgA",
                  param = "alpha",
                  strat = "typhi")

