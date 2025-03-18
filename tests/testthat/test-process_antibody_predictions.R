test_that(
  desc = "process_antibody_predictions() generates valid predictions",
  code = {
    skip_if(getRversion() < "4.4.1")  # Ensure compatibility
    
    # ---------------------------------------------------------------------------
    # Step 1: Prepare Dataset & Run JAGS Model
    # ---------------------------------------------------------------------------
    results <- prepare_and_run_jags(
      id = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    dat <- results$dat
    full_dat <- results$dataset  # Full processed dataset
    
    # ---------------------------------------------------------------------------
    # Step 2: Extract Parameter Medians from the Full Dataset JAGS Output
    # ---------------------------------------------------------------------------
    param_medians <- process_jags_output(
      jags_post   = results$nepal_sees_jags_post2,
      dataset     = full_dat,
      run_until   = 9,
      id          = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # Validate that param_medians is not empty
    expect_true(nrow(param_medians) > 0, info = "param_medians should not be empty")
    
    # Replace any NA with 0 (if needed)
    param_medians <- param_medians %>%
      mutate(across(everything(), ~ ifelse(is.na(.), 0, .)))
    
    # ---------------------------------------------------------------------------
    # Step 3: Process Antibody Predictions & Compute Residuals
    # ---------------------------------------------------------------------------
    predictions <- process_antibody_predictions(
      dat2 = full_dat,
      param_medians_wide = param_medians,
      file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
      strat = "bldculres",
      id = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # ---------------------------------------------------------------------------
    # Step 4: Validate the Output
    # ---------------------------------------------------------------------------
    # The expected output should be a tibble with these columns:
    # "Subject", "antigen_iso", "y0", "y1", "t1", "alpha", "shape", and "id"
    expect_s3_class(predictions, "tbl_df")
    required_cols <- c("Subject", "antigen_iso", "y0", "y1", "t1", "alpha", "shape", "id")
    expect_true(all(required_cols %in% colnames(predictions)), info = "Output missing required columns")
  }
)


