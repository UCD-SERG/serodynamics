
data <- serodynamics::nepal_sees_jags_output

# Specifying isotype and stratification for traceplot.
plot_density(
             data = data,
             iso = "HlyE_IgA",
             strat = "typhi")
