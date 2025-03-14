test_that(
  desc = "process_antibody_predictions() generates valid predictions",
  code = {
    skip_if(getRversion() < "4.4.1")  # Ensure compatibility
    
    # ---------------------------------------------------------------------------
    # Step 1: Prepare Dataset & Run JAGS Model
    # ---------------------------------------------------------------------------
    # Run the JAGS model for the specified subject and antigen.
    results <- prepare_and_run_jags(
      id = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # For prediction processing, we use the full dataset.
    dat_full <- results$dataset
    
    # ---------------------------------------------------------------------------
    # Step 2: Extract Parameter Medians from the Full Dataset JAGS Output
    # ---------------------------------------------------------------------------
    param_medians <- process_jags_output(
      jags_post   = results$nepal_sees_jags_post2,
      dataset     = results$dataset,
      run_until   = 9,
      id          = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # Validate that param_medians is not empty
    expect_true(nrow(param_medians) > 0, info = "param_medians should not be empty")
    
    # Replace any missing values with 0 (if needed)
    param_medians <- param_medians %>%
      mutate(across(everything(), ~ ifelse(is.na(.), 0, .)))
    
    # ---------------------------------------------------------------------------
    # Step 3: Process Antibody Predictions and Compute Residuals
    # ---------------------------------------------------------------------------
    predictions <- process_antibody_predictions(
      dat2 = dat_full,
      param_medians_wide = param_medians,
      file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
      strat = "bldculres",
      id = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # ---------------------------------------------------------------------------
    # Step 4: Validate the Output
    # ---------------------------------------------------------------------------
    # Expected columns include "Subject", "antigen_iso", "y0", "y1", "t1", "alpha", "shape", and "id".
    expect_true(tibble::is_tibble(predictions), info = "Output should be a tibble")
    required_cols <- c("Subject", "antigen_iso", "y0", "y1", "t1", "alpha", "shape", "id")
    expect_true(all(required_cols %in% colnames(predictions)), info = "Output missing required columns")
  }
)
