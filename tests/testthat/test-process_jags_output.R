test_that(
  desc = "process_jags_output() correctly extracts median parameters",
  code = {
    skip_if(getRversion() < "4.4.1")  # Ensure compatibility
    
    # Run prepare_and_run_jags to get JAGS output
    results <- prepare_and_run_jags()
    jags_post <- results$jags_post
    
    # Process JAGS output
    param_medians <- process_jags_output(jags_post, remove_last_subject = TRUE)
    
    # Check that the output is a tibble
    expect_true(tibble::is_tibble(param_medians))
    
    # Ensure key columns exist
    expect_true(all(c("Subject", "antigen_iso", "y0", "y1", "t1", "alpha", "r") %in% colnames(param_medians)))
  }
)
