
test_that(
  desc = "results are consistent with traceplot ggplot output",
  code = {
    skip_if(getRversion() < "4.4.1") # 4.3.3 had issues

    data <- serodynamics::nepal_sees_jags_output |>
      suppressWarnings()

    results <- plot_jags_trace(data) |>
      # Testing for any errors
      expect_no_error()
    # Test to ensure output is a list object
    expect_true(is.list(results))
    # Test to ensure that a piece of the list is a ggplot object
    vdiffr::expect_doppelganger("tracedx_typhoid_plot", 
                                results$newperson$typhi$HlyE_IgA)
  }
)

test_that(
  desc = "results are consistent with traceplot ggplot output for
  sees_npl_1 and sees_npl_2",
  code = {
    skip_if(getRversion() < "4.4.1") # 4.3.3 had issues
    
    data <- serodynamics::nepal_sees_jags_output |>
      suppressWarnings()
    
    results <- plot_jags_trace(data, id = c("sees_npl_1", "sees_npl_2")) |>
      # Testing for any errors
      expect_no_error()
    # Test to ensure output is a list object
    expect_true(is.list(results))
    # Test to ensure that a piece of the list is a ggplot object
    vdiffr::expect_doppelganger("tracedx_typhoid_plot_ids", 
                                results$sees_npl_1$typhi$HlyE_IgA)
  }
)
