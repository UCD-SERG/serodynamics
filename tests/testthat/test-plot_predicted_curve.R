test_that(
  desc = "plot_predicted_curve() returns a valid ggplot object with and without observed data",
  code = {
    skip_if(getRversion() < "4.4.1")
    
    # Load the pre-saved JAGS output fixture.
    results <- readRDS(testthat::test_path("fixtures", "jags_results_128.rds"))
    
    # Extract outputs.
    dat <- results$dat
    dataset <- results$dataset
    jags_post <- results$nepal_sees_jags_post
    
    # Process JAGS output (partial processing).
    param_medians <- process_jags_output(
      jags_post   = jags_post,
      dataset     = dataset,
      run_until   = 7,
      id          = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # Generate predicted curve plot without observed data.
    plot_pred_only <- plot_predicted_curve(param_medians)
    expect_true(ggplot2::is.ggplot(plot_pred_only))
    vdiffr::expect_doppelganger(title = "predicted_curve_no_observed", plot_pred_only)
    
    # Generate predicted curve plot with observed data.
    plot_with_observed <- plot_predicted_curve(param_medians, dat = dat)
    expect_true(ggplot2::is.ggplot(plot_with_observed))
    vdiffr::expect_doppelganger(title = "predicted_curve_with_observed", plot_with_observed)
  }
)
