test_that("prep_priors_multi_b() returns correctly-shaped hyperparams", {
  out <- prep_priors_multi_b(n_blocks = 3)
  
  expect_type(out, "list")
  expect_named(out, c("OmegaP", "nuP", "OmegaB", "nuB"))
  
  expect_equal(dim(out$OmegaP), c(5, 5))
  expect_equal(dim(out$OmegaB), c(3, 3))
  expect_length(diag(out$OmegaB), 3)
  expect_true(is.numeric(out$nuP))
  expect_true(is.numeric(out$nuB))
})

test_that("prep_priors_multi_b() validations work", {
  expect_error(prep_priors_multi_b(n_blocks = 0), "positive integer")
  expect_error(prep_priors_multi_b(n_blocks = 2, omega_p_scale = 1:4), 
               "length 5")
  expect_error(prep_priors_multi_b(n_blocks = 2, omega_b_scale = 1:3), 
               "`n_blocks`")
})
