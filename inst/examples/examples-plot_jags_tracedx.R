
data <- serodynamics::nepal_sees_jags_output

# Specifying isotype, parameter, and stratification for traceplot.
plot_jags_trace(
                data = data,
                iso = "HlyE_IgA",
                strat = "typhi")
