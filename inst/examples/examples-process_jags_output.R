# Example usage of process_jags_output()

# Ensure JAGS is available before running
if (!is.element(runjags::findjags(), c("", NULL))) {
  
  # ---------------------------------------------------------------------------
  # Step 1: Run JAGS Model via prepare_and_run_jags()
  # ---------------------------------------------------------------------------
  # Prepare the dataset and run the JAGS models by specifying the subject and antigen.
  results <- prepare_and_run_jags(
    id = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # Extract outputs from the results list:
  # - jags_post_subject: JAGS output for the specific subject-antigen pair.
  # - jags_post_full: JAGS output for the entire dataset.
  # - dataset: The full processed dataset.
  jags_post_subject <- results$nepal_sees_jags_post
  jags_post_full    <- results$nepal_sees_jags_post2
  dataset           <- results$dataset
  
  # ---------------------------------------------------------------------------
  # Step 2: Process JAGS Output to Extract Median Parameter Estimates
  # ---------------------------------------------------------------------------
  # (a) Partial processing: Run until step 7 (wide-format pivot only)
  param_medians_partial <- process_jags_output(
    jags_post   = jags_post_subject,
    dataset     = dataset,
    run_until   = 7,
    id          = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # (b) Full processing: Run until step 9 (includes subject mapping & filtering)
  param_medians_full <- process_jags_output(
    jags_post   = jags_post_full,
    dataset     = dataset,
    run_until   = 9,
    id          = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # ---------------------------------------------------------------------------
  # Step 3: Display Processed Median Parameter Estimates
  # ---------------------------------------------------------------------------
  cat("Partial Processing (run_until = 7):\n")
  print(head(param_medians_partial))
  
  cat("Full Processing (run_until = 9):\n")
  print(head(param_medians_full))
}
