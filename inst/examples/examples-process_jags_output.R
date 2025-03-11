# Example usage of process_jags_output()

# Ensure JAGS is available before running
if (!is.element(runjags::findjags(), c("", NULL))) {
  
  # Run JAGS model first
  results <- prepare_and_run_jags()
  jags_post <- results$jags_post
  
  # Process JAGS output to extract median parameter estimates
  param_medians <- process_jags_output(jags_post, remove_last_subject = TRUE)
  
  # Display processed medians
  print(head(param_medians))
}
