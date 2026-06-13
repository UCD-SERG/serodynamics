test_that("sim_case_data_2a returns well-formed two-biomarker case data", {
  mu_g <- c(0, 3, 2.3, -4, -1)
  mu_a <- c(0.2, 3.1, 2.2, -3.8, -1.1)
  sg <- diag(c(0.09, 0.16, 0.09, 0.16, 0.09))
  sa <- diag(c(0.09, 0.16, 0.09, 0.16, 0.09))
  cv <- c(0.054, 0.080, 0.0, 0.064, 0.0)
  vt <- c(0, 7, 14, 28, 56, 90, 140, 200)

  res <- sim_case_data_2a(
    n = 30, mu_g = mu_g, mu_a = mu_a,
    sigma_g = sg, sigma_a = sa, c_vec = cv,
    visit_times = vt, noise_sd = 0.15, seed = 1
  )
  d <- res$data

  # required columns survive as_case_data (which also adds visit_num)
  expect_true(all(c("id", "antigen_iso", "value", "timeindays", "visit_num")
                  %in% names(d)))
  # shape: n subjects x 2 biomarkers x visits
  expect_equal(nrow(d), 30 * 2 * length(vt))
  expect_equal(length(unique(d$id)), 30)
  expect_setequal(unique(d$antigen_iso), c("HlyE_IgG", "HlyE_IgA"))
  # visit_num runs 1..n_visit within each subject x biomarker
  vn <- d$visit_num[d$id == d$id[1] & d$antigen_iso == "HlyE_IgG"]
  expect_equal(sort(vn), seq_along(vt))
  # measurements are valid antibody values
  expect_true(all(d$value > 0) && all(is.finite(d$value)))
})

test_that("sim_case_data_2a truth matches the requested correlation and is reproducible", {
  args <- list(
    n = 20, mu_g = c(0, 3, 2.3, -4, -1), mu_a = c(0.2, 3.1, 2.2, -3.8, -1.1),
    sigma_g = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
    sigma_a = diag(c(0.09, 0.16, 0.09, 0.16, 0.09)),
    c_vec = c(0.054, 0.080, 0.0, 0.064, 0.0), seed = 99
  )
  r1 <- do.call(sim_case_data_2a, args)
  r2 <- do.call(sim_case_data_2a, args)

  # truth$rho is c_vec / sqrt(varG * varA)
  expect_equal(
    r1$truth$rho,
    args$c_vec / sqrt(diag(args$sigma_g) * diag(args$sigma_a))
  )
  # same seed -> identical data
  expect_equal(r1$data$value, r2$data$value)
})
