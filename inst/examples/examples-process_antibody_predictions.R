# Example usage of process_antibody_predictions()

# Ensure JAGS is available before running
if (!is.element(runjags::findjags(), c("", NULL))) {
  
  # ---------------------------------------------------------------------------
  # Step 1: Prepare Dataset & Run JAGS Model
  # ---------------------------------------------------------------------------
  # This step filters the dataset for the subject "sees_npl_128" and antigen "HlyE_IgA"
  # and runs two JAGS models (subject-specific and full dataset models).
  results <- prepare_and_run_jags(
    id = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # Extract the filtered dataset (dat) and the full dataset (dataset)
  dat <- results$dat         # Filtered data for subject "sees_npl_128" & antigen "HlyE_IgA"
  dataset <- results$dataset   # The full dataset
  
  # ---------------------------------------------------------------------------
  # Step 2: Process JAGS Output to Extract Median Parameters
  # ---------------------------------------------------------------------------
  # Here we process the full dataset JAGS output to obtain median parameter estimates.
  param_medians <- process_jags_output(
    jags_post = results$nepal_sees_jags_post2,  # Full dataset model output
    dataset = dataset,
    run_until = 9,                             # Run full processing (steps 1-9)
    id = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # ---------------------------------------------------------------------------
  # Step 3: Generate Predictions & Re-run JAGS Based on Residuals
  # ---------------------------------------------------------------------------
  # The process_antibody_predictions() function computes predicted antibody responses,
  # calculates residuals, prepares a modified dataset (using absolute residuals),
  # re-runs the JAGS model, and finally processes the new output.
  predictions <- process_antibody_predictions(
    dat2 = dataset,                          # Pass the full dataset as dat2
    param_medians_wide = param_medians,      # Use median parameters from the full model
    file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
    strat = "bldculres",
    id = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # ---------------------------------------------------------------------------
  # Step 4: Display Results
  # ---------------------------------------------------------------------------
  # Print the first few rows of the new median parameter estimates obtained from the
  # residual-based model re-run.
  print(head(predictions))
}
