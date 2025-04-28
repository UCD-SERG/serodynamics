test_that(
  desc = "process_jags_samples() works with run_mod output and dataset",
  {
    skip_if(getRversion() < "4.4.1")
    
    # 1) Build the full dataset:
    dataset <- nepal_sees |>
      as_case_data(
        id_var        = "id",
        biomarker_var = "antigen_iso",
        value_var     = "value",
        time_in_days  = "timeindays"
      ) |>
      rename(
        strat      = bldculres,
        timeindays = dayssincefeveronset,
        value      = result
      )
    
    # 2) Run the model over the entire dataset:
    model <- run_mod(
      data         = dataset,
      file_mod     = serodynamics_example("model.jags"),
      nchain       = 2,
      nadapt       = 100,
      nburn        = 100,
      nmc          = 500,
      niter        = 1000,
      strat        = "strat",
      include_subs = TRUE
    )
    
    # 3) Pull out the full MCMC samples for that one ID + antigen
    full_samples <- process_jags_samples(
      jags_post   = model,
      dataset     = dataset,
      id          = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
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
