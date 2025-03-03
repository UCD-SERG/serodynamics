
test_that(
  desc = "results are consistent with ggplot output",
  code = {
    skip_if(getRversion() < "4.4.1") # 4.3.3 had issues
    library(runjags)
    library(dplyr)

    data <- serodynamics::nepal_sees_jags_post |>
      suppressWarnings()

    withr::with_seed(
      1,
      code = {
        results <- plot_jags_dens(data)
      }
    ) |>
      # Testing for any errors
      expect_no_error()
    # Test to ensure output is a list object
    expect_true(is.list(results))
    # Test to ensure that a piece of the list is a ggplot object
    vdiffr::expect_doppelganger("typhoid_plot", results$typhi$HlyE_IgA)
  }
)
