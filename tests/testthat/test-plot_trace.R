
test_that(
  desc = "results are consistent with traceplot ggplot output",
  code = {
    skip_if(getRversion() < "4.4.1") # 4.3.3 had issues

    data <- serodynamics::nepal_sees_jags_output |>
      suppressWarnings()

    results <- plot_trace(data) |>
      # Testing for any errors
      expect_no_error()
    # Test to ensure output is a list object
    expect_true(is.list(results))
    # Test to ensure that a piece of the list is a ggplot object
    vdiffr::expect_doppelganger("tracedx_typhoid_plot", results$typhi$HlyE_IgA)
  }
)

test_that(
  desc = "one iso across several strata returns a plot per stratum",
  code = {
    data <- serodynamics::nepal_sees_jags_output
    strata <- unique(data$Stratification)

    results <- plot_trace(data, iso = "HlyE_IgA") |>
      suppressWarnings()

    expect_length(strata, 2)
    expect_named(results, strata)
    second_stratum <- strata[2]
    second_plots <- results[[second_stratum]]
    expect_s3_class(second_plots$HlyE_IgA, "ggplot")
  }
)
