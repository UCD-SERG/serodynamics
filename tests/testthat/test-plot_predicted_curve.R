test_that(
  desc = "plot_predicted_curve() works with run_mod output and 
  on-the-fly dataset",
  code = {
    skip_if(getRversion() < "4.4.1")
    
    # Use the pre-computed package data instead of a fixture
    sr_model <- serodynamics::nepal_sees_jags_output

    # 5a. Plot (linear axes) with both model curves + observed points
    plot1 <- plot_predicted_curve(
      model              = sr_model,
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
      model              = sr_model,
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
      model              = sr_model,
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
      model              = sr_model,
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

# Tests for assay-specific Y-axis labels
testthat::test_that(
  "plot_predicted_curve() uses correct Y-axis label for ELISA_OD assay",
  {
    plot_elisa_od <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = "sees_npl_128",
      antigen_iso     = "HlyE_IgA",
      dataset         = serodynamics::nepal_sees,
      show_quantiles  = TRUE,
      log_y           = FALSE,
      assay           = "ELISA_OD"
    )
    
    # Check that the plot is a ggplot object
    testthat::expect_s3_class(plot_elisa_od, "ggplot")
    
    # Check that the Y-axis label is correct
    testthat::expect_equal(plot_elisa_od$labels$y, "Optical density (OD)")
  }
)

testthat::test_that(
  "plot_predicted_curve() uses correct Y-axis label for Kinetic_ELISA assay",
  {
    plot_kinetic <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = "sees_npl_128",
      antigen_iso     = "HlyE_IgA",
      dataset         = serodynamics::nepal_sees,
      show_quantiles  = TRUE,
      log_y           = FALSE,
      assay           = "Kinetic_ELISA"
    )
    
    testthat::expect_s3_class(plot_kinetic, "ggplot")
    testthat::expect_equal(plot_kinetic$labels$y, "Kinetic ELISA signal")
  }
)

testthat::test_that(
  "plot_predicted_curve() uses correct Y-axis label for multiplex-bg assay",
  {
    plot_multiplex <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = "sees_npl_128",
      antigen_iso     = "HlyE_IgA",
      dataset         = serodynamics::nepal_sees,
      show_quantiles  = TRUE,
      log_y           = FALSE,
      assay           = "multiplex-bg"
    )
    
    testthat::expect_s3_class(plot_multiplex, "ggplot")
    testthat::expect_equal(
      plot_multiplex$labels$y, 
      "MFI (background-subtracted)"
    )
  }
)

testthat::test_that(
  "plot_predicted_curve() adds log scale notation to assay-specific labels",
  {
    plot_log <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = "sees_npl_128",
      antigen_iso     = "HlyE_IgA",
      dataset         = serodynamics::nepal_sees,
      show_quantiles  = TRUE,
      log_y           = TRUE,
      assay           = "ELISA_OD"
    )
    
    testthat::expect_s3_class(plot_log, "ggplot")
    testthat::expect_equal(
      plot_log$labels$y, 
      "Optical density (OD) (log scale)"
    )
  }
)

testthat::test_that(
  "plot_predicted_curve() handles case-insensitive assay types",
  {
    plot_lower <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = "sees_npl_128",
      antigen_iso     = "HlyE_IgA",
      dataset         = serodynamics::nepal_sees,
      show_quantiles  = TRUE,
      log_y           = FALSE,
      assay           = "elisa_od"  # lowercase
    )
    
    plot_upper <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = "sees_npl_128",
      antigen_iso     = "HlyE_IgA",
      dataset         = serodynamics::nepal_sees,
      show_quantiles  = TRUE,
      log_y           = FALSE,
      assay           = "ELISA_OD"  # uppercase
    )
    
    # Both should have the same label
    testthat::expect_equal(plot_lower$labels$y, plot_upper$labels$y)
    testthat::expect_equal(plot_lower$labels$y, "Optical density (OD)")
  }
)

testthat::test_that(
  "plot_predicted_curve() warns and uses default label for unknown assay",
  {
    testthat::expect_warning(
      plot_unknown <- plot_predicted_curve(
        model           = serodynamics::nepal_sees_jags_output,
        ids             = "sees_npl_128",
        antigen_iso     = "HlyE_IgA",
        dataset         = serodynamics::nepal_sees,
        show_quantiles  = TRUE,
        log_y           = FALSE,
        assay           = "Unknown_Assay"
      ),
      regexp = "Unsupported assay type"
    )
    
    # Should fall back to default label
    testthat::expect_equal(plot_unknown$labels$y, "ELISA units")
  }
)

testthat::test_that(
  "plot_predicted_curve() can infer assay from dataset with assay column",
  {
    # Create a modified dataset with an assay column
    test_data <- serodynamics::nepal_sees
    test_data$assay <- "Kinetic_ELISA"
    
    plot_inferred <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = "sees_npl_128",
      antigen_iso     = "HlyE_IgA",
      dataset         = test_data,
      show_quantiles  = TRUE,
      log_y           = FALSE
      # Note: no assay parameter provided, should infer from dataset
    )
    
    testthat::expect_s3_class(plot_inferred, "ggplot")
    testthat::expect_equal(plot_inferred$labels$y, "Kinetic ELISA signal")
  }
)

testthat::test_that(
  "plot_predicted_curve() prioritizes explicit assay over dataset inference",
  {
    # Create a modified dataset with an assay column
    test_data <- serodynamics::nepal_sees
    test_data$assay <- "Kinetic_ELISA"
    
    # But explicitly specify a different assay
    plot_explicit <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = "sees_npl_128",
      antigen_iso     = "HlyE_IgA",
      dataset         = test_data,
      show_quantiles  = TRUE,
      log_y           = FALSE,
      assay           = "ELISA_OD"  # Override the dataset value
    )
    
    testthat::expect_s3_class(plot_explicit, "ggplot")
    # Should use the explicit assay, not the one in dataset
    testthat::expect_equal(plot_explicit$labels$y, "Optical density (OD)")
  }
)

testthat::test_that(
  "plot_predicted_curve() uses default label when no assay info available",
  {
    # No assay parameter and dataset doesn't have assay columns
    plot_default <- plot_predicted_curve(
      model           = serodynamics::nepal_sees_jags_output,
      ids             = "sees_npl_128",
      antigen_iso     = "HlyE_IgA",
      dataset         = serodynamics::nepal_sees,  # No assay column
      show_quantiles  = TRUE,
      log_y           = FALSE
    )
    
    testthat::expect_s3_class(plot_default, "ggplot")
    testthat::expect_equal(plot_default$labels$y, "ELISA units")
  }
)
