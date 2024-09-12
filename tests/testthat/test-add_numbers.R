# Load the testthat

library(testthat)

# Test cases for the add_numbers() function
test_that("add_numbers works as expected", {
  
  # Check if the sum of 1 and 1 equals 2
  expect_equal(add_numbers(1, 1), 2)
  
  # Check if the sum of -1 and 1 equals 0
  expect_equal(add_numbers(-1, 1), 0)
  
  # Check if the sum of 0 and 0 equals 0
  expect_equal(add_numbers(0, 0), 0)
  
  # Check if the sum of 1.5 and 2.5 equals 4
  expect_equal(add_numbers(1.5, 2.5), 4)
})
