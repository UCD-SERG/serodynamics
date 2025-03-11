test_that(
  desc = "process_antibody_predictions() generates valid predictions",
  code = {
    skip_if(getRversion() < "4.4.1")  # Ensure compatibility
    
    # Run previous functions to get required inputs
    results <- prepare_and_run_jags()
    dat <- results$dat
    jags_post <- results$jags_post
    param_medians <- process_jags_output(jags_post, remove_last_subject = TRUE)
    
    # Generate predictions
    predictions <- process_antibody_predictions(dat, param_medians)
    
    # Check that output is a tibble
    expect_true(tibble::is_tibble(predictions))
    
    # Ensure key columns exist
    expect_true(all(c("dayssincefeveronset", "predicted_result") %in% colnames(predictions)))
  }
)
