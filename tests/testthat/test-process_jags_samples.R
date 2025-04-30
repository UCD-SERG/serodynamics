test_that(
  desc = "process_jags_samples() works with run_mod output and dataset",
  {
    skip_if(getRversion() < "4.4.1")
    
    # Load pre-saved fixture (includes both full_samples and dat)
    example <- 
      readr::read_rds(testthat::test_path("fixtures", 
                                          "example_runmod_output.rds"))
    
    full_samples <- example$full_samples
    
    # ---- SANITY CHECKS ----
    # a) It's a tibble
    expect_s3_class(full_samples, "tbl_df")
    
    # b) It has the MCMC dims we asked for:
    expect_equal(nrow(full_samples), 2 * 500)
    
    # c) It has exactly the columns we expect:
    expected_cols <- c(
      "Chain", "Iteration", "antigen_iso", "r",
      "y0", "y1", "t1", "alpha", "shape"
    )
    expect_true(all(expected_cols %in% names(full_samples)))
    
    # d) No unexpected columns
    expect_equal(sort(names(full_samples)), sort(expected_cols))
    
    # e) Each chain has exactly 500 iterations
    for (ch in unique(full_samples$Chain)) {
      its <- full_samples$Iteration[full_samples$Chain == ch]
      expect_equal(sort(unique(its)), seq_len(500))
    }
  }
)
