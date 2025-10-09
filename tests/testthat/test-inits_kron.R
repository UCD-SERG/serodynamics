test_that("inits_kron() returns a list of initial values", {
  ini <- inits_kron(chain = 1)
  expect_type(ini, "list")
  expect_gt(length(ini), 0)
})
