
test_that(
  desc = "results are consistent with ggplot rhat dotplot output",
  code = {
    skip_if(getRversion() < "4.4.1") # 4.3.3 had issues

    data <- serodynamics::nepal_sees_jags_output |>
      suppressWarnings()

    # Testing for any errors:
    results <- plot_jags_Rhat(data) |> expect_no_error()
      
    # Test to ensure output is a list object:
    expect_true(is.list(results))
    
    # Test to ensure that a piece of the list is a ggplot object:
    results$newperson$typhi$HlyE_IgA |> 
      vdiffr::expect_doppelganger(title = "rhat_typhoid_plot")
  }
)

test_that(
  desc = "results are consistent with ggplot rhat dotplot output",
  code = {
    skip_if(getRversion() < "4.4.1") # 4.3.3 had issues
    
    data <- serodynamics::nepal_sees_jags_output |>
      suppressWarnings()
    
    # Testing for any errors:
    results <- plot_jags_Rhat(data, id = c("sees_npl_1", "sees_npl_2"))|>
      expect_no_error()
    
    # Test to ensure output is a list object:
    expect_true(is.list(results))
    
    # Test to ensure that a piece of the list is a ggplot object:
    results$sees_npl_1$typhi$HlyE_IgA |> 
      vdiffr::expect_doppelganger(title = "rhat_typhoid_plot_ids")
  }
)
