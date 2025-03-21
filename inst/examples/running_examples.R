if (!is.element(runjags::findjags(), c("", NULL))) {
  
  # ------------------------------------------------------------------------------
  # Step 1: Prepare Dataset & Run JAGS Model
  # ------------------------------------------------------------------------------
  # This step reads the dataset, extracts the required subject ("sees_npl_128") and 
  # antigen ("HlyE_IgA") data, and runs two JAGS models:
  #   - A subject-specific model (stored in 'nepal_sees_jags_post')
  #   - A full dataset model (stored in 'nepal_sees_jags_post2')
  # The function returns a list containing:
  #   - dat: Filtered data for the selected subject-antigen pair.
  #   - dataset: The full dataset.
  #   - nepal_sees_jags_post: JAGS output for the selected subject.
  #   - nepal_sees_jags_post2: JAGS output for the full dataset.
  # ------------------------------------------------------------------------------
  jags_results <- prepare_and_run_jags(
    id = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # Extract results from the returned list
  dat <- jags_results$dat
  dataset <- jags_results$dataset
  nepal_sees_jags_post <- jags_results$nepal_sees_jags_post
  nepal_sees_jags_post2 <- jags_results$nepal_sees_jags_post2
  
  # ------------------------------------------------------------------------------
  # Step 2: Process JAGS Output to Extract Median Parameters
  # ------------------------------------------------------------------------------
  # Process the JAGS output from two different model runs:
  #
  # (a) Full processing (steps 1-9):
  #     Uses the full dataset JAGS model and performs subject mapping and filtering.
  param_medians_full <- process_jags_output(
    jags_post = nepal_sees_jags_post2,  # Full dataset model output
    dataset = dataset,                # Full dataset for subject mapping
    run_until = 9,                    # Run full processing (steps 1-9)
    id = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # (b) Partial processing (run until wide-format pivot, step 7 only):
  #     Uses the subject-specific JAGS model without additional subject mapping.
  param_medians_partial <- process_jags_output(
    jags_post = nepal_sees_jags_post,
    dataset = dataset,
    run_until = 7,                    # Run until pivot (step 7 only)
    id = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # Display the two different outputs for comparison
  print("Partial Processing Output (subject-specific model):")
  print(head(param_medians_partial))
  
  print("Full Processing Output (full dataset model):")
  print(head(param_medians_full))
  
  # ------------------------------------------------------------------------------
  # Step 3: Generate Predicted Antibody Response Curves
  # ------------------------------------------------------------------------------
  # The function 'plot_predicted_curve' generates predicted antibody response curves 
  # using the median parameter estimates and overlays observed data if provided.
  #
  # (a) Using the subject-specific (partial) model:
  plot_typhi_curves_partial_legend <- plot_predicted_curve(
    param_medians_wide = param_medians_partial, 
    dat = dat,
    legend_obs = "Observed Data",
    legend_mod1 = "Model Partial Predictions"
  )
  print(plot_typhi_curves_partial_legend)
  
  # (b) Using the full dataset model:
  plot_typhi_curves_full_legend <- plot_predicted_curve(
    param_medians_wide = param_medians_full, 
    dat = dat,
    legend_obs = "Observed Data",
    legend_mod1 = "Model Full Predictions"
  )
  print(plot_typhi_curves_full_legend)
  
  # (c) Overlay both model predictions:
  plot_typhi_curves_legend <- plot_predicted_curve(
    param_medians_wide = param_medians_full, 
    param_medians_wide2 = param_medians_partial, 
    dat = dat,
    legend_obs = "Observed Data",
    legend_mod1 = "Model Full Predictions",
    legend_mod2 = "Model Partial Predictions"
  )
  print(plot_typhi_curves_legend)
  
  # ------------------------------------------------------------------------------
  # Step 4: Generate Predictions & Re-run JAGS Based on Residuals
  # ------------------------------------------------------------------------------
  # This step computes residuals between observed and predicted responses,
  # prepares a modified dataset (using absolute residuals), re-runs the JAGS model,
  # and processes the new JAGS output.
  param_medians_wide_resid <- process_antibody_predictions(
    dat = dataset, 
    param_medians_wide = param_medians_full,
    file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
    strat = "bldculres",
    id = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # Display the processed median parameters from the re-run model
  print("Residual-based Model Output:")
  print(param_medians_wide_resid)
  
  # Generate predicted antibody response curve based on the residual-based model,
  # with a legend indicating observed data and the residual-based model predictions.
  plot_typhi_curves_resid_legend <- plot_predicted_curve(
    param_medians_wide = param_medians_wide_resid, 
    dat = dat,
    legend_obs = "Observed Data",
    legend_mod1 = "Residual-based Model Predictions"
  )
  print(plot_typhi_curves_resid_legend)
}
