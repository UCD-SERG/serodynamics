
test_that("priors are modifiable", {
  prep_priors(max_antigens = 2, 
              mu_hyp_param = c(1.0,  5.0, 0.0, -2.0, -3.0),
              prec_hyp_param = c(0.01, 0.01, 0.01, 0.01, 0.01),
              omega_param = c(1.0, 50.0, 1.0, 5.0, 1.0),
              wishdf_param = 15,
              prec_logy_hyp_param = c(4.0, 1.0)) |>
    expect_snapshot_value(style = "deparse")
})

test_that("Expect error when priors are not supplied", {
  prep_priors(max_antigens = 2) |>
    expect_error()
})

test_that("Expect error for mu.hyp.param under exponential", {
  prep_priors(max_antigens = 2, 
              mu_hyp_param = c(1.0,  5.0, 0.0, -2.0, -3.0),
              prec_hyp_param = c(0.01, 0.01, 0.01, 0.01, 0.01),
              omega_param = c(1.0, 50.0, 1.0, 5.0, 1.0),
              wishdf_param = 15,
              prec_logy_hyp_param = c(4.0, 1.0),
              decay_type == "exponential") |>
    expect_error()
})
