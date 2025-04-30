test_that(
  desc = "plot_predicted_curve() works with run_mod output and 
  on-the-fly dataset",
  code = {
    skip_if(getRversion() < "4.4.1")
    
    # Load pre-saved fixture (includes both full_samples and dat)
    example <- 
      readr::read_rds(testthat::test_path("fixtures", 
                                          "example_runmod_output.rds"))
    
    full_samples <- example$full_samples
    dat <- example$dat
    
    # 5a. Plot (linear axes) with both model curves + observed points
    plot1 <- plot_predicted_curve(
      param_medians_wide = full_samples,
      dataset                = dat,
      legend_obs         = "Observed Data",
      legend_mod1        = "Full Model Predictions",
      show_quantiles     = TRUE,
      log_scale          = FALSE,
      log_x              = FALSE,
      show_all_curves    = TRUE
    )
    expect_true(ggplot2::is_ggplot(plot1))
    vdiffr::expect_doppelganger("predicted_curve_linear", plot1)
    
    # 5b. Plot (log10 axes) with both model curves + observed points
    plot2 <- plot_predicted_curve(
      param_medians_wide = full_samples,
      dataset                = dat,
      legend_obs         = "Observed Data",
      legend_mod1        = "Full Model Predictions",
      show_quantiles     = TRUE,
      log_scale          = TRUE,
      log_x              = FALSE,
      show_all_curves    = TRUE
    )
    expect_true(ggplot2::is_ggplot(plot2))
    vdiffr::expect_doppelganger("predicted_curve_log", plot2)
  }
)
