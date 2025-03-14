test_that(
  desc = "prepare_and_run_jags() returns a valid dataset and JAGS output",
  code = {
    skip_if(getRversion() < "4.4.1")  # Ensure compatibility with R 4.4.1 or later
    
    # Run the function with a specified subject and antigen
    results <- prepare_and_run_jags(
      id = "sees_npl_128",
      antigen_iso = "HlyE_IgA"
    )
    
    # Check that the function returns a list
    expect_true(is.list(results))
    
    # Check that the list contains the expected components
    expect_true("dat" %in% names(results))
    expect_true("dataset" %in% names(results))
    expect_true("nepal_sees_jags_post" %in% names(results))
    expect_true("nepal_sees_jags_post2" %in% names(results))
    
    # Check that 'dat' and 'dataset' are tibbles
    expect_true(tibble::is_tibble(results$dat))
    expect_true(tibble::is_tibble(results$dataset))
    
    # Check that the JAGS outputs are not NULL
    expect_false(is.null(results$nepal_sees_jags_post))
    expect_false(is.null(results$nepal_sees_jags_post2))
  }
)
