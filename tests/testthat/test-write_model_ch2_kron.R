test_that("write_model_ch2_kron() writes a model file with n_blocks (no B)", {
  p <- write_model_ch2_kron(file.path(tempdir(), "model_ch2_kron.jags"))
  expect_true(file.exists(p))
  txt <- readLines(p, warn = FALSE)
  # key patterns that caught bugs 
  expect_true(any(grepl("for \\(b in 1:n_blocks\\)", txt)))
  expect_true(any(grepl("TauB\\[1:n_blocks,1:n_blocks\\]", txt)))
  expect_false(any(grepl("\\bfor \\(b in 1:B\\)", txt)))
})
