
test_that("prior predict creates figure", {
  plot_prior_posterior(nepal_sees_jags_output,
                       distributions = c("Prior", "Population posterior")) +
    scale_x_log10()
})
