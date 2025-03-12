# Step 1: Prepare dataset & Run JAGS model in one step
jags_results <- prepare_and_run_jags()

# Extract results
dat <- jags_results$dat
nepal_sees_jags_post <- jags_results$jags_post

# Step 2: Process JAGS output
param_medians_wide_128 <- process_jags_output(nepal_sees_jags_post, remove_last_subject = TRUE)

# Step 3: Generate predicted antibody response curve
plot_paratyphi_curves <- plot_predicted_curve(param_medians_wide_128,dat)
print(plot_paratyphi_curves)

# Step 4: Generate predictions & re-run JAGS
param_medians_wide_128_2 <- process_antibody_predictions(
  dat = dat, 
  param_medians_wide = param_medians_wide_128, 
  file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
  strat = "bldculres"
)

# Step 5: Generate and display the residual-based curve
plot_paratyphi_curves2 <- plot_predicted_curve(param_medians_wide_128_2)
print(plot_paratyphi_curves2)
