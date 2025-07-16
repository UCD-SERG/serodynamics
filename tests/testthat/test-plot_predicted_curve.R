test_that(
  desc = "plot_predicted_curve() works with run_mod output and 
  on-the-fly dataset",
  code = {
    skip_if(getRversion() < "4.4.1")
    
    # Use the pre-computed package data instead of a fixture
    sr_model <- serodynamics::nepal_sees_jags_output

    # Prepare the 'dat' object for overlay, mirroring the main example
    dat <- serodynamics::nepal_sees |>
      as_case_data(
        id_var        = "id",
        biomarker_var = "antigen_iso",
        value_var     = "value",
        time_in_days  = "timeindays"
      ) |>
      dplyr::rename(
        timeindays = dayssincefeveronset,
        value      = result
      ) |>
      dplyr::filter(id == "sees_npl_128", antigen_iso == "HlyE_IgA")
    
    # 5a. Plot (linear axes) with both model curves + observed points
    plot1 <- plot_predicted_curve(
      sr_model           = sr_model,
      id                 = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = dat,
      legend_obs         = "Observed data",
      legend_median        = "Median prediction",
      show_quantiles     = TRUE,
      log_y          = FALSE,
      log_x              = FALSE,
      show_all_curves    = TRUE
    )
    expect_true(ggplot2::is_ggplot(plot1))
    vdiffr::expect_doppelganger("predicted_curve_linear", plot1)
    
    # 5b. Plot (log10 axes) with both model curves + observed points
    plot2 <- plot_predicted_curve(
      sr_model           = sr_model,
      id                 = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = dat,
      legend_obs         = "Observed data",
      legend_median        = "Median prediction",
      show_quantiles     = TRUE,
      log_y          = TRUE,
      log_x              = FALSE,
      show_all_curves    = TRUE
    )
    expect_true(ggplot2::is_ggplot(plot2))
    vdiffr::expect_doppelganger("predicted_curve_log", plot2)
    
    # 5c. Plot with log10 x-axis
    plot3 <- plot_predicted_curve(
      sr_model           = sr_model,
      id                 = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = dat,
      legend_obs         = "Observed data",
      legend_median        = "Median prediction",
      show_quantiles     = TRUE,
      log_y          = FALSE,
      log_x              = TRUE,
      show_all_curves    = TRUE
    )
    expect_true(ggplot2::is_ggplot(plot3))
    vdiffr::expect_doppelganger("predicted_curve_logx", plot3)
    
    # 5d. Plot with custom x-axis limits
    plot4 <- plot_predicted_curve(
      sr_model           = sr_model,
      id                 = "sees_npl_128",
      antigen_iso        = "HlyE_IgA",
      dataset            = dat,
      legend_obs         = "Observed data",
      legend_median        = "Median prediction",
      show_quantiles     = TRUE,
      log_y          = FALSE,
      log_x              = FALSE,
      show_all_curves    = TRUE,
      xlim               = c(0, 500)
    )
    expect_true(ggplot2::is_ggplot(plot4))
    vdiffr::expect_doppelganger("predicted_curve_xlim", plot4)
  }
)
