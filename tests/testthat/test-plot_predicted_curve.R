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
    testthat::expect_true(ggplot2::is_ggplot(plot1))
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
    testthat::expect_true(ggplot2::is_ggplot(plot2))
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
    testthat::expect_true(ggplot2::is_ggplot(plot3))
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
    testthat::expect_true(ggplot2::is_ggplot(plot4))
    vdiffr::expect_doppelganger("predicted_curve_xlim", plot4)
  }
)

# Helper function for repeated test logic
check_plot_multi <- function(ids, antigen, log_y = FALSE) {
  dat_multi <- serodynamics::nepal_sees |>
    as_case_data(
      id_var        = "id",
      biomarker_var = "antigen_iso",
      value_var     = "value",
      time_in_days  = "timeindays"
    ) |>
    # Use bare names like the first test block to avoid tidyselect warnings
    dplyr::rename(
      timeindays = dayssincefeveronset,
      value      = result
    ) |>
    dplyr::filter(id %in% ids, antigen_iso == antigen)
  
  plot_multi <- plot_predicted_curve(
    sr_model       = serodynamics::nepal_sees_jags_output,
    id             = ids,
    antigen_iso    = antigen,
    dataset        = dat_multi,
    show_all_curves = TRUE,
    log_y          = log_y,
    facet_by_id    = TRUE
  )
  
  # Assertions
  testthat::expect_true(ggplot2::is_ggplot(plot_multi))
  
  built <- ggplot2::ggplot_build(plot_multi)
  n_facets <- length(unique(dat_multi$id))
  testthat::expect_equal(length(unique(built$layout$layout$PANEL)), n_facets)

  # Check legend labels by accessing the labels defined in the plot scales.
  # This is more robust than parsing the gtable or relying on breaks.
  legend_labels <- c(
    built$plot$labels$colour,
    built$plot$labels$fill
  )

  testthat::expect_true(
    all(c(
      "Median prediction",
      "Observed data",
      "Posterior samples",
      "95% credible interval"
    ) %in% legend_labels)
  )
  
  return(plot_multi)
}

# Test cases using the helper
testthat::test_that(
  "plot_predicted_curve() works with 2 IDs (faceting, original legend)",
  {
    plot_multi <- check_plot_multi(
      ids = c("sees_npl_128", "sees_npl_131"),
      antigen = "HlyE_IgA"
    )
    vdiffr::expect_doppelganger("predicted-curve-multi-id-2", plot_multi)
  }
)

testthat::test_that(
  "plot_predicted_curve() works with 3 IDs (faceting, log_y)",
  {
    plot_multi <- check_plot_multi(
      ids = c("sees_npl_28", "sees_npl_128", "sees_npl_131"),
      antigen = "HlyE_IgA",
      log_y = TRUE
    )
    vdiffr::expect_doppelganger("predicted-curve-multi-id-3", plot_multi)
  }
)

testthat::test_that(
  "plot_predicted_curve() works with 4 IDs (faceting, log_y)",
  {
    plot_multi <- check_plot_multi(
      ids = c("sees_npl_28", "sees_npl_68", "sees_npl_128", "sees_npl_131"),
      antigen = "HlyE_IgA",
      log_y = TRUE
    )
    vdiffr::expect_doppelganger("predicted-curve-multi-id-4", plot_multi)
  }
)
