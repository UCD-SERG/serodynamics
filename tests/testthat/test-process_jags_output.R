test_that(
  desc = "process_jags_output() correctly extracts median parameters",
  code = {
    skip_if(getRversion() < "4.4.1")
    
    # Load the pre-saved JAGS output for subject sees_npl_128 and antigen HlyE_IgA.
    results <- readRDS(testthat::test_path("fixtures", "jags_results_128.rds"))
    
    # Use the subject-specific JAGS output from the fixture.
    jags_post <- results$nepal_sees_jags_post
    
    # Extract median parameter estimates using partial processing (run_until = 7)
    param_medians <- process_jags_output(
      jags_post   = jags_post,
      dataset     = results$dataset,
      run_until   = 7,
      id          = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # Validate output is not empty.
    expect_true(nrow(param_medians) > 0, info = "param_medians should not be empty")
    
    # Ensure all necessary columns exist.
    required_columns <- c("Subject", "antigen_iso", "y0", "y1", "t1", "alpha", "shape")
    expect_true(all(required_columns %in% colnames(param_medians)), info = "Missing required columns")
    
    # Ensure no missing values in the extracted parameters.
    expect_true(all(complete.cases(param_medians)), info = "Missing values in extracted parameters")
  }
)
