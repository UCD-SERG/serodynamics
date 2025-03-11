
test_that(
  desc = "results are consistent with ggplot output",
  code = {
    skip_if(getRversion() < "4.4.1") # 4.3.3 had issues

    data <- serodynamics::nepal_sees_jags_post |>
      suppressWarnings()

    # Testing for any errors:
    results <- plot_jags_dens(data) |> expect_no_error()
      
    # Test to ensure output is a list object:
    expect_true(is.list(results))
    
    # Test to ensure that a piece of the list is a ggplot object:
    results$typhi$HlyE_IgA |> 
      vdiffr::expect_doppelganger(title = "typhoid_plot")
  }
)
