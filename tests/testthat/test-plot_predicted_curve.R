test_that(
  desc = "plot_predicted_curve() works with run_mod output and 
  on-the-fly dataset",
  code = {
    skip_if(getRversion() < "4.4.1")
    
    # Use the pre-computed package data instead of a fixture
    sr_model <- serodynamics::nepal_sees_jags_output

    # 5a. Plot (linear axes) with both model curves + observed points
    plot1 <- plot_predicted_curve(
      sr_model           = sr_model,
      id                 = "sees_npl_128",
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
      sr_model           = sr_model,
      id                 = "sees_npl_128",
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
      sr_model           = sr_model,
      id                 = "sees_npl_128",
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
      sr_model           = sr_model,
      id                 = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = serodynamics::nepal_sees,
      log_y              = FALSE,
      log_x              = FALSE,
      show_all_curves    = TRUE,
      xlim               = c(0, 500)
    )
    vdiffr::expect_doppelganger("predicted_curve_xlim", plot4)
  }
)

# Test cases using the helper
testthat::test_that(
  "plot_predicted_curve() works with 2 IDs (faceting, original legend)",
  {
    plot_multi <- plot_predicted_curve(
      sr_model        = serodynamics::nepal_sees_jags_output,
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
    plot_multi <- plot_predicted_curve(
      sr_model        = serodynamics::nepal_sees_jags_output,
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
    plot_multi <- plot_predicted_curve(
      sr_model        = serodynamics::nepal_sees_jags_output,
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
