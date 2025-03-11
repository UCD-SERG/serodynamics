test_that(
  desc = "prepare_and_run_jags() returns a valid dataset and JAGS output",
  code = {
    skip_if(getRversion() < "4.4.1")  # Ensure compatibility
    
    # Run the function
    results <- prepare_and_run_jags()
    
    # Check that the function returns a list
    expect_true(is.list(results))
    
    # Check that the list contains 'dat' and 'jags_post'
    expect_true("dat" %in% names(results))
    expect_true("jags_post" %in% names(results))
    
    # Check that dat is a tibble
    expect_true(tibble::is_tibble(results$dat))
    
    # Check that jags_post is not NULL
    expect_false(is.null(results$jags_post))
  }
)
