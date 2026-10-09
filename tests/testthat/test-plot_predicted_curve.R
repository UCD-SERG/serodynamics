test_that(
  desc = "plot_predicted_curve() works with run_serodynamics output and
  on-the-fly dataset",
  code = {
    skip_on_cran()
    skip_if_not(
      Sys.getenv("RUN_HEAVY_TESTS") == "true",
      message = "Skipping heavy test unless RUN_HEAVY_TESTS=true"
    )
    skip_if_not_installed("vdiffr")
    skip_if(getRversion() < "4.4.1")

    # Use the pre-computed package data instead of a fixture
    sr_model <- serodynamics::nepal_sees_jags_output

    # 5a. Plot (linear axes) with both model curves + observed points
    plot1 <- plot_predicted_curve(
      model              = sr_model,
      ids                = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = serodynamics::nepal_sees,
      show_quantiles     = TRUE,
      log_y              = FALSE,
      log_x              = FALSE,
      show_all_curves    = TRUE
    )
    vdiffr::expect_doppelganger("predicted_curve_linear", plot1)

    # 5b. Plot (log10 axes) with both model curves + observed points
    plot2 <- plot_predicted_curve(
      model              = sr_model,
      ids                = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = serodynamics::nepal_sees,
      show_quantiles     = TRUE,
      log_y              = TRUE,
      log_x              = FALSE,
      show_all_curves    = TRUE
    )
    vdiffr::expect_doppelganger("predicted_curve_log", plot2)

    # 5c. Plot with log10 x-axis
    plot3 <- plot_predicted_curve(
      model              = sr_model,
      ids                = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = serodynamics::nepal_sees,
      show_quantiles     = TRUE,
      log_y              = FALSE,
      log_x              = TRUE,
      show_all_curves    = TRUE
    )
    vdiffr::expect_doppelganger("predicted_curve_logx", plot3)

    # 5d. Plot with custom x-axis limits
    plot4 <- plot_predicted_curve(
      model              = sr_model,
      ids                = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = serodynamics::nepal_sees,
      log_y              = FALSE,
      log_x              = FALSE,
      show_all_curves    = TRUE,
      xlim               = c(0, 500)
    )
    vdiffr::expect_doppelganger("predicted_curve_xlim", plot4)

    # Confirm that exponential models use exponential decay downstream.
    exp_model <- tibble::tibble(
      Chain = 1L,
      Iteration = 1L,
      Iso_type = "test",
      Parameter = c("y0", "y1", "t1", "alpha", "shape"),
      value = c(1, 10, 5, 0.1, 1),
      Subject = "subject-1",
      Stratification = "None"
    )
    attr(exp_model, "decay_type") <- "exponential"

    exp_plot <- plot_predicted_curve(
      model = exp_model,
      ids = "subject-1",
      antigen_iso = "test",
      show_quantiles = FALSE,
      show_all_curves = TRUE,
      facet_by_id = FALSE
    )

    exp_curve_data <- suppressWarnings(
      ggplot2::layer_data(exp_plot, 1)
    )
    expected <- ab(
      t = 10,
      y0 = 1,
      y1 = 10,
      t1 = 5,
      alpha = 0.1,
      shape = 1,
      decay_type = "exponential"
    )

    expect_equal(
      exp_curve_data$y[exp_curve_data$x == 10],
      expected
    )
  }
)

# Test cases using the helper
testthat::test_that(
  "plot_predicted_curve() works with 2 IDs (faceting, original legend)",
  {
    skip_on_cran()
    skip_if_not(
      Sys.getenv("RUN_HEAVY_TESTS") == "true",
      message = "Skipping heavy JAGS test unless RUN_HEAVY_TESTS=true"
    )
    skip_if_not_installed("vdiffr")
    plot_multi <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = c("sees_npl_128", "sees_npl_131"),
      antigen_iso     = "HlyE_IgA",
      dataset         = serodynamics::nepal_sees,
      show_all_curves = TRUE,
      log_y           = FALSE,
      facet_by_id     = TRUE
    )
    vdiffr::expect_doppelganger("predicted-curve-multi-id-2", plot_multi)
  }
)

testthat::test_that(
  "plot_predicted_curve() works with 3 IDs (faceting, log_y)",
  {
    skip_on_cran()
    skip_if_not(
      Sys.getenv("RUN_HEAVY_TESTS") == "true",
      message = "Skipping heavy JAGS test unless RUN_HEAVY_TESTS=true"
    )
    skip_if_not_installed("vdiffr")
    plot_multi <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = c("sees_npl_2", "sees_npl_128", "sees_npl_131"),
      antigen_iso     = "HlyE_IgA",
      dataset         = serodynamics::nepal_sees,
      show_all_curves = TRUE,
      log_y           = TRUE,
      facet_by_id     = TRUE
    )
    vdiffr::expect_doppelganger("predicted-curve-multi-id-3", plot_multi)
  }
)

testthat::test_that(
  "plot_predicted_curve() works with 4 IDs (faceting, log_y)",
  {
    skip_on_cran()
    skip_if_not(
      Sys.getenv("RUN_HEAVY_TESTS") == "true",
      message = "Skipping heavy JAGS test unless RUN_HEAVY_TESTS=true"
    )
    skip_if_not_installed("vdiffr")
    plot_multi <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = c("sees_npl_2", "sees_npl_133", "sees_npl_128",
                          "sees_npl_131"),
      antigen_iso     = "HlyE_IgA",
      dataset         = serodynamics::nepal_sees,
      show_all_curves = TRUE,
      log_y           = TRUE,
      facet_by_id     = TRUE
    )
    vdiffr::expect_doppelganger("predicted-curve-multi-id-4", plot_multi)
  }
)
