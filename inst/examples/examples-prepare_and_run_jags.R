# Example usage of prepare_and_run_jags()

# Ensure JAGS is available before running
if (!is.element(runjags::findjags(), c("", NULL))) {
  
  # Run function to prepare dataset and execute the JAGS models
  results <- prepare_and_run_jags(
    id = "sees_npl_128",
    antigen_iso = "HlyE_IgA"
  )
  
  # Extract outputs
  dat <- results$dat                   # Filtered data for the selected subject-antigen pair
  dataset <- results$dataset           # The full processed dataset
  jags_post <- results$nepal_sees_jags_post     # JAGS output for the selected subject-antigen pair
  jags_post2 <- results$nepal_sees_jags_post2   # JAGS output for the entire dataset
  
  # Display summaries of the JAGS model outputs
  print("Summary of subject-specific JAGS output:")
  print(summary(jags_post))
  
  print("Summary of full dataset JAGS output:")
  print(summary(jags_post2))
}
