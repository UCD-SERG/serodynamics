test_that(
  desc = "plot_predicted_curve() returns a valid ggplot object with and without observed data",
  code = {
    skip_if(getRversion() < "4.1.1")  # Ensure compatibility
    
    # Step 1: Run previous functions to get necessary inputs
    results <- prepare_and_run_jags()
    dat <- results$dat
    jags_post <- results$jags_post
    param_medians <- process_jags_output(jags_post, remove_last_subject = TRUE)
    
    # Step 2: Generate plot **without observed data**
    plot_pred_only <- plot_predicted_curve(param_medians)
    
    # Ensure the output is a ggplot object
    expect_true(ggplot2::is.ggplot(plot_pred_only))
    
    # Snapshot testing for predicted curve only
    vdiffr::expect_doppelganger(title = "predicted_curve_no_observed", plot_pred_only)
    
    # Step 3: Generate plot **with observed data**
    plot_with_observed <- plot_predicted_curve(param_medians, dat = dat)
    
    # Ensure the output is a ggplot object
    expect_true(ggplot2::is.ggplot(plot_with_observed))
    
    # Snapshot testing for predicted curve with observed data
    vdiffr::expect_doppelganger(title = "predicted_curve_with_observed", plot_with_observed)
  }
)
