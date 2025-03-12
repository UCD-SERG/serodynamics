# Example usage of prepare_and_run_jags()

# Ensure JAGS is available before running
if (!is.element(runjags::findjags(), c("", NULL))) {
  
  # Run function to prepare dataset & execute JAGS model
  results <- prepare_and_run_jags()
  
  # Extract outputs
  dat <- results$dat
  jags_post <- results$jags_post
  
  # Display summary of JAGS output
  print(summary(jags_post))
}
