sigma_G_ex <- diag(c(0.34, 1.14, 0.64, 0.84, 0.27)^2)
sigma_A_ex <- diag(c(0.77, 1.35, 0.98, 1.50, 0.30)^2)
mu_G_ex <- c(-0.22, 5.23, 1.92, -4.10, -0.37)
mu_A_ex <- c(0.06, 4.33, 1.96, -2.71, 0.35)
rho_ex <- c(-0.81, 0.62, 0.88, 0.77, 0.36)

cross_corr_of <- function(cp) {
  sigma_full <- attr(cp, "truth")$sigma_full
  n_par <- nrow(sigma_full) / 2
  vapply(
    seq_len(n_par),
    function(j) {
      sigma_full[j, n_par + j] /
        sqrt(sigma_full[j, j] * sigma_full[n_par + j, n_par + j])
    },
    numeric(1)
  )
}

test_that("the injected correlation is the realised correlation", {
  withr::with_seed(1, {
    cp <- make_corr_curve_params(
      n_iter = 500, mu_G = mu_G_ex, mu_A = mu_A_ex,
      sigma_G = sigma_G_ex, sigma_A = sigma_A_ex, rho = rho_ex
    )
  })
  expect_equal(cross_corr_of(cp), rho_ex)
  expect_equal(attr(cp, "truth")$cross_corr, rho_ex)
})

test_that("within-biomarker covariances are left untouched by rho", {
  withr::with_seed(1, {
    cp <- make_corr_curve_params(
      n_iter = 200, mu_G = mu_G_ex, mu_A = mu_A_ex,
      sigma_G = sigma_G_ex, sigma_A = sigma_A_ex, rho = rho_ex
    )
  })
  sigma_full <- attr(cp, "truth")$sigma_full
  expect_equal(sigma_full[1:5, 1:5], sigma_G_ex)
  expect_equal(sigma_full[6:10, 6:10], sigma_A_ex)
})

test_that("rho = 0 gives an exactly zero cross-biomarker block", {
  withr::with_seed(1, {
    cp <- make_corr_curve_params(
      n_iter = 200, mu_G = mu_G_ex, mu_A = mu_A_ex,
      sigma_G = sigma_G_ex, sigma_A = sigma_A_ex, rho = rep(0, 5)
    )
  })
  expect_equal(max(abs(attr(cp, "truth")$sigma_full[1:5, 6:10])), 0)
})

test_that("returned curve parameters are valid", {
  withr::with_seed(2, {
    cp <- make_corr_curve_params(
      n_iter = 300, mu_G = mu_G_ex, mu_A = mu_A_ex,
      sd_G = sqrt(diag(sigma_G_ex)), sd_A = sqrt(diag(sigma_A_ex)),
      rho = rep(0.3, 5)
    )
  })
  expect_named(cp, c("iter", "antigen_iso", "y0", "y1", "t1", "alpha", "r"))
  expect_equal(nrow(cp), 600)
  expect_true(all(cp$y0 > 0))
  expect_true(all(cp$y1 > cp$y0))
  expect_true(all(cp$r > 1))
  expect_true(all(is.finite(cp$alpha)))
})

test_that("the decay rate is recovered on the log_k scale", {
  withr::with_seed(3, {
    cp <- make_corr_curve_params(
      n_iter = 4000, mu_G = mu_G_ex, mu_A = mu_A_ex,
      sigma_G = sigma_G_ex, sigma_A = sigma_A_ex, rho = rho_ex
    )
  })
  igg <- cp[cp$antigen_iso == "HlyE_IgG", ]
  log_k <- log(igg$alpha) + (igg$r - 1) * log(igg$y1)
  expect_equal(mean(log_k), mu_G_ex[4], tolerance = 0.1)
  expect_equal(sd(log_k), sqrt(sigma_G_ex[4, 4]), tolerance = 0.1)
})

test_that("sd_G / sd_A give independent within-biomarker parameters", {
  withr::with_seed(4, {
    cp <- make_corr_curve_params(
      n_iter = 100, mu_G = mu_G_ex, mu_A = mu_A_ex,
      sd_G = rep(0.5, 5), sd_A = rep(0.5, 5), rho = rep(0.2, 5)
    )
  })
  sigma_G_out <- attr(cp, "truth")$sigma_G
  expect_equal(max(abs(sigma_G_out[upper.tri(sigma_G_out)])), 0)
})

test_that("unattainable correlations are refused", {
  expect_error(
    make_corr_curve_params(
      n_iter = 10, mu_G = mu_G_ex, mu_A = mu_A_ex,
      sigma_G = sigma_G_ex, sigma_A = sigma_A_ex, rho = rep(0.999, 5)
    ),
    regexp = "not attainable"
  )
  expect_error(
    make_corr_curve_params(
      n_iter = 10, mu_G = mu_G_ex, mu_A = mu_A_ex,
      sigma_G = sigma_G_ex, sigma_A = sigma_A_ex, rho = rep(1.5, 5)
    ),
    regexp = "\\[-1, 1\\]"
  )
  expect_error(
    make_corr_curve_params(
      n_iter = 10, mu_G = mu_G_ex, mu_A = mu_A_ex, rho = rep(0, 5)
    ),
    regexp = "sigma_G"
  )
})

test_that("rho_admissible agrees with make_corr_curve_params", {
  good <- rho_admissible(sigma_G_ex, sigma_A_ex, rho_ex)
  bad <- rho_admissible(sigma_G_ex, sigma_A_ex, rep(0.999, 5))
  expect_true(good$admissible)
  expect_gt(good$min_eig, 0)
  expect_false(bad$admissible)
  expect_lt(bad$min_eig, 0)
})
