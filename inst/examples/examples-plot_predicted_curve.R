# Example usage of plot_predicted_curve()

# Ensure JAGS is available before running
if (!is.element(runjags::findjags(), c("", NULL))) {
  
  # Step 1: Prepare dataset & Run JAGS model
  jags_results <- prepare_and_run_jags()
  
  # Extract results
  dat <- jags_results$dat
  nepal_sees_jags_post <- jags_results$jags_post
  
  # Step 2: Process JAGS output
  param_medians_wide_128 <- process_jags_output(nepal_sees_jags_post, remove_last_subject = TRUE)
  
  # Step 3: Generate predicted antibody response curve **without observed data**
  plot_pred_only <- plot_predicted_curve(param_medians_wide_128)
  print(plot_pred_only)  # Display predicted curve
  
  # Step 4: Generate predicted curve **with observed data overlaid**
  plot_with_observed <- plot_predicted_curve(param_medians_wide_128, dat = dat)
  print(plot_with_observed)  # Display observed + predicted curve
}

