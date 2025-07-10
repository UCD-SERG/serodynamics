test_that(
  desc = "plot_predicted_curve() works with run_mod output and 
  on-the-fly dataset",
  code = {
    skip_if(getRversion() < "4.4.1")
    
    # Load pre-saved fixture (includes model output and sample data)
    example <- 
      readr::read_rds(testthat::test_path("fixtures", 
                                          "example_runmod_output.rds"))
    
    jags_post <- example$model
    dat <- example$dat
    
    # 5a. Plot (linear axes) with both model curves + observed points
    plot1 <- plot_predicted_curve(
      jags_post          = jags_post,
      id                 = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = dat,
      legend_obs         = "Observed Data",
      legend_mod1        = "Median Prediction",
      show_quantiles     = TRUE,
      log_scale          = FALSE,
      log_x              = FALSE,
      show_all_curves    = TRUE
    )
    expect_true(ggplot2::is_ggplot(plot1))
    vdiffr::expect_doppelganger("predicted_curve_linear", plot1)
    
    # 5b. Plot (log10 axes) with both model curves + observed points
    plot2 <- plot_predicted_curve(
      jags_post          = jags_post,
      id                 = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = dat,
      legend_obs         = "Observed Data",
      legend_mod1        = "Median Prediction",
      show_quantiles     = TRUE,
      log_scale          = TRUE,
      log_x              = FALSE,
      show_all_curves    = TRUE
    )
    expect_true(ggplot2::is_ggplot(plot2))
    vdiffr::expect_doppelganger("predicted_curve_log", plot2)
    
    # 5c. Plot with log10 x-axis
    plot3 <- plot_predicted_curve(
      jags_post          = jags_post,
      id                 = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = dat,
      legend_obs         = "Observed Data",
      legend_mod1        = "Median Prediction",
      show_quantiles     = TRUE,
      log_scale          = FALSE,
      log_x              = TRUE,
      show_all_curves    = TRUE
    )
    expect_true(ggplot2::is_ggplot(plot3))
    vdiffr::expect_doppelganger("predicted_curve_logx", plot3)
    
    # 5d. Plot with custom x-axis limits
    plot4 <- plot_predicted_curve(
      jags_post          = jags_post,
      id                 = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = dat,
      legend_obs         = "Observed Data",
      legend_mod1        = "Median Prediction",
      show_quantiles     = TRUE,
      log_scale          = FALSE,
      log_x              = FALSE,
      show_all_curves    = TRUE,
      xlim               = c(0, 500)
    )
    expect_true(ggplot2::is_ggplot(plot4))
    vdiffr::expect_doppelganger("predicted_curve_xlim", plot4)
  }
)
