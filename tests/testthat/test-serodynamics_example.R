test_that("`serodynamics_example()` works", {
  found_path <- serodynamics_example("model.jags")
  expected_path <- fs::path_package(
    package = "serodynamics",
    "extdata/model.jags")
  expect_equal(found_path, expected_path)
  
  expected_files <- c("model.dobson.jags", 
                      "model.jags")
  
  found_files <- serodynamics_example()
  
  missing_files <- setdiff(expected_files, found_files)
  
  expect_equal(missing_files, character(0))
})
