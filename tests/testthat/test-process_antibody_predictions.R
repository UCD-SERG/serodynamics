test_that(
  desc = "process_antibody_predictions() generates valid predictions",
  code = {
    skip_if(getRversion() < "4.4.1")  # Ensure compatibility
    
    # Run JAGS model
    results <- prepare_and_run_jags()
    dat <- results$dat
    jags_post <- results$jags_post
    
    # Extract parameter medians
    param_medians <- process_jags_output(jags_post, remove_last_subject = TRUE)
    
    # Check if param_medians is not empty before proceeding
    expect_true(nrow(param_medians) > 0, info = "param_medians should not be empty")
    
    # Ensure no missing values before calling the function
    param_medians <- param_medians %>%
      mutate(across(everything(), ~ ifelse(is.na(.), 0, .)))  # Replace NA with 0
    
    # Run function
    predictions <- process_antibody_predictions(dat, param_medians)
    
    # Ensure output is a tibble and contains expected columns
    expect_true(tibble::is_tibble(predictions), info = "Output should be a tibble")
    expect_true(all(c("predicted_result", "id") %in% colnames(predictions)), info = "Output missing required columns")
  }
)
