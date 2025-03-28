test_that(
  desc = "process_antibody_predictions() generates valid predictions",
  code = {
    skip_if(getRversion() < "4.4.1")
    
    # Load the pre-saved JAGS output fixture.
    results <- readRDS(testthat::test_path("fixtures", "jags_results_128.rds"))
    dat <- results$dat
    full_dat <- results$dataset  # Full processed dataset from fixture.
    
    # Extract median parameters from the full dataset JAGS output.
    param_medians <- process_jags_output(
      jags_post   = results$nepal_sees_jags_post2,
      dataset     = full_dat,
      run_until   = 9,
      id          = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # Validate that param_medians is not empty.
    expect_true(nrow(param_medians) > 0, info = "param_medians should not be empty")
    
    # Replace any NA with 0 (if needed).
    param_medians <- param_medians %>%
      dplyr::mutate(across(everything(), ~ ifelse(is.na(.), 0, .)))
    
    # Process antibody predictions and compute residuals.
    predictions <- process_antibody_predictions(
      dat2 = full_dat,
      param_medians_wide = param_medians,
      file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
      strat = "bldculres",
      id = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # Validate the output is a tibble and contains required columns.
    expect_s3_class(predictions, "tbl_df")
    required_cols <- c("Subject", "antigen_iso", "y0", "y1", "t1", "alpha", "shape", "id")
    expect_contains(object = colnames(predictions), expected = required_cols)
  }
)
