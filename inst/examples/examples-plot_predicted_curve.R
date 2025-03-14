# Example usage of plot_predicted_curve()

# Ensure JAGS is available before running
if (!is.element(runjags::findjags(), c("", NULL))) {
  
  # ---------------------------------------------------------------------------
  # Step 1: Prepare Dataset & Run JAGS Model
  # ---------------------------------------------------------------------------
  # Run the model for subject "sees_npl_128" and antigen "HlyE_IgA"
  jags_results <- prepare_and_run_jags(
    id = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # Extract outputs:
  # - dat: Filtered data for the selected subject-antigen pair
  # - dataset: The full processed dataset
  # - nepal_sees_jags_post: JAGS output for the subject-specific model
  dat <- jags_results$dat
  dataset <- jags_results$dataset
  
  # ---------------------------------------------------------------------------
  # Step 2: Process JAGS Output to Extract Median Parameter Estimates
  # ---------------------------------------------------------------------------
  # Here we run the processing until step 7 (partial processing)
  param_medians_wide_128 <- process_jags_output(
    jags_post   = jags_results$nepal_sees_jags_post,
    dataset     = dataset,
    run_until   = 7,
    id          = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # ---------------------------------------------------------------------------
  # Step 3: Generate Predicted Antibody Response Curve WITHOUT Observed Data
  # ---------------------------------------------------------------------------
  plot_pred_only <- plot_predicted_curve(
    param_medians_wide = param_medians_wide_128
  )
  print(plot_pred_only)  # Display predicted curve
  
  # ---------------------------------------------------------------------------
  # Step 4: Generate Predicted Antibody Response Curve WITH Observed Data Overlaid
  # ---------------------------------------------------------------------------
  plot_with_observed <- plot_predicted_curve(
    param_medians_wide = param_medians_wide_128,
    dat = dat,
    legend_obs = "Observed Data",
    legend_mod1 = "Model Predictions"
  )
  print(plot_with_observed)  # Display observed + predicted curve
}


