# Example usage of process_antibody_predictions()

# Ensure JAGS is available before running
if (!is.element(runjags::findjags(), c("", NULL))) {
  
  # Run JAGS model & process output
  results <- prepare_and_run_jags()
  dat <- results$dat
  jags_post <- results$jags_post
  param_medians <- process_jags_output(jags_post, remove_last_subject = TRUE)
  
  # Generate predicted antibody response
  predictions <- process_antibody_predictions(dat, param_medians)
  
  # Display results
  print(head(predictions))
}
