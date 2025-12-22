test_that("clean_priors drops only legacy fields and preserves attributes", {
  x <- list(
    mu.hyp = 1, 
    prec.hyp = 2,
    omega = 3, wishdf = 4, Omega = 5, WishDF = 6, prec.par = 7,
    keep_me = 8
  )
  # NEW: set the attribute that clean_priors() should keep
  attr(x, "used_priors") <- c("mu.hyp", "prec.hyp", "keep_me")
  
  y <- clean_priors(x)
  
  # legacy fields removed
  dropped <- c("omega", "wishdf", "Omega", "WishDF", "prec.par")
  expect_false(any(dropped %in% names(y)))
  
  # intended fields kept 
  expect_true(all(c("mu.hyp", "prec.hyp", "keep_me") %in% names(y)))
  expect_equal(y$mu.hyp, 1)
  expect_equal(y$prec.hyp, 2)
  expect_equal(y$keep_me, 8)
  
  # NEW: attribute preserved
  expect_equal(attr(y, "used_priors"), c("mu.hyp", "prec.hyp", "keep_me"))
})
