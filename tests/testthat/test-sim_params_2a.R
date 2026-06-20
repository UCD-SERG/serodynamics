test_that("sim_params_2a sample covariance recovers the truth (large n)", {
  set.seed(42)
  mu_g <- c(0, 3, 2.3, -4, -1)
  mu_a <- c(0.2, 3.1, 2.2, -3.8, -1.1)
  sg <- diag(c(0.09, 0.16, 0.09, 0.16, 0.09))
  sa <- diag(c(0.09, 0.16, 0.09, 0.16, 0.09))
  cv <- c(0.054, 0.080, 0.0, 0.064, 0.0)
  
  sim <- sim_params_2a(20000, mu_g, mu_a, sg, sa, cv, seed = 7)
  emp <- stats::cov(sim$log_par)
  
  # cross-biomarker, same-parameter covariances recovered
  emp_c <- diag(emp[1:5, 6:10])
  expect_equal(emp_c, cv, tolerance = 0.05)
  # means recovered
  expect_equal(colMeans(sim$log_par), c(mu_g, mu_a), tolerance = 0.05)
  # reported rho matches definition
  expect_equal(sim$rho, cv / sqrt(diag(sg) * diag(sa)))
})

test_that("jags_node_dims infers array dimensions from coda names", {
  nm <- c("lambda[1,1]", "lambda[2,5]", "prec.par[2,5,5]", "mu.par[2,5]")
  d <- jags_node_dims(nm)
  expect_equal(d[["lambda"]], c(2, 5))
  expect_equal(d[["prec.par"]], c(2, 5, 5))
  expect_equal(d[["mu.par"]], c(2, 5))
})

test_that("get_node_matrix extracts the right cells", {
  v <- c("lambda[1,1]" = 11, "lambda[1,2]" = 12,
         "lambda[2,1]" = 21, "lambda[2,2]" = 22)
  m <- get_node_matrix(v, "lambda", 2, 2)
  expect_equal(m, matrix(c(11, 21, 12, 22), nrow = 2))
  
  v3 <- c("prec.par[1,1,1]" = 1, "prec.par[1,1,2]" = 2,
          "prec.par[1,2,1]" = 3, "prec.par[1,2,2]" = 4,
          "prec.par[2,1,1]" = 5, "prec.par[2,1,2]" = 6,
          "prec.par[2,2,1]" = 7, "prec.par[2,2,2]" = 8)
  expect_equal(get_node_matrix(v3, "prec.par", 2, 2, slice = 2),
               matrix(c(5, 7, 6, 8), nrow = 2))
})
