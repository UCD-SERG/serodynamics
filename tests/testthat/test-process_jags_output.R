test_that(
  desc = "process_jags_output() correctly extracts median parameters",
  code = {
    skip_if(getRversion() < "4.4.1")
    
    # Run JAGS
    results <- prepare_and_run_jags()
    jags_post <- results$jags_post
    
    # Extract median parameter estimates
    param_medians <- process_jags_output(jags_post, remove_last_subject = TRUE)
    
    # Validate output is not empty
    expect_true(nrow(param_medians) > 0, info = "param_medians should not be empty")
    
    # Ensure all necessary columns exist
    required_columns <- c("Subject", "antigen_iso", "y0", "y1", "t1", "alpha", "r")
    expect_true(all(required_columns %in% colnames(param_medians)), info = "Missing required columns")
    
    # Ensure no missing values
    expect_true(all(complete.cases(param_medians)), info = "Missing values in extracted parameters")
  }
)

