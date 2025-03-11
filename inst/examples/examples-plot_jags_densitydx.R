
if (!is.element(runjags::findjags(), c("", NULL))) {

  data <- serodynamics::nepal_sees_jags_post

  plot_jags_dens(
                 data = data,
                 iso = "HlyE_IgA",
                 param = "alpha",
                 strat = "typhi")
}
