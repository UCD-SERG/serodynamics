test_that(
  desc = "plot_predicted_curve() returns a valid ggplot object with and without observed data",
  code = {
    skip_if(getRversion() < "4.4.1")  # Ensure compatibility
    
    # ---------------------------------------------------------------------------
    # Step 1: Prepare Dataset & Run JAGS Model
    # ---------------------------------------------------------------------------
    # Run the model for subject "sees_npl_128" and antigen "HlyE_IgA"
    results <- prepare_and_run_jags(
      id = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # Extract outputs:
    # - dat: Filtered data for the selected subject-antigen pair
    # - dataset: The full processed dataset
    # - nepal_sees_jags_post: JAGS output for the subject-specific model
    dat <- results$dat
    dataset <- results$dataset
    jags_post <- results$nepal_sees_jags_post
    
    # ---------------------------------------------------------------------------
    # Step 2: Process JAGS Output to Extract Median Parameter Estimates
    # ---------------------------------------------------------------------------
    # Here we run the processing until step 7 (partial processing)
    param_medians <- process_jags_output(
      jags_post   = jags_post,
      dataset     = dataset,
      run_until   = 7,
      id          = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # ---------------------------------------------------------------------------
    # Step 3: Generate Predicted Antibody Response Curve WITHOUT Observed Data
    # ---------------------------------------------------------------------------
    plot_pred_only <- plot_predicted_curve(param_medians)
    
    # Ensure the output is a ggplot object
    expect_true(ggplot2::is.ggplot(plot_pred_only))
    
    # Snapshot testing for predicted curve only
    vdiffr::expect_doppelganger(title = "predicted_curve_no_observed", plot_pred_only)
    
    # ---------------------------------------------------------------------------
    # Step 4: Generate Predicted Antibody Response Curve WITH Observed Data Overlaid
    # ---------------------------------------------------------------------------
    plot_with_observed <- plot_predicted_curve(param_medians, dat = dat)
    
    # Ensure the output is a ggplot object
    expect_true(ggplot2::is.ggplot(plot_with_observed))
    
    # Snapshot testing for predicted curve with observed data
    vdiffr::expect_doppelganger(title = "predicted_curve_with_observed", plot_with_observed)
  }
)
