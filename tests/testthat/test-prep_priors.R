
test_that("priors are modifiable", {
  prep_priors(max_antigens = 2, 
              mu_hyp_param = c(1.0,  5.0, 0.0, -2.0, -3.0),
              prec_hyp_param = c(0.01, 0.01, 0.01, 0.01, 0.01),
              omega_param = c(1.0, 50.0, 1.0, 5.0, 1.0),
              wishdf_param = 15,
              prec_logy_hyp_param = c(4.0, 1.0)) |>
    expect_snapshot_value(style = "deparse")
})

test_that("Preparing priors for exponential", {
  prep_priors(max_antigens = 2, 
              mu_hyp_param = c(1.0,  5.0, 0.0, -2.0),
              prec_hyp_param = c(0.01, 0.01, 0.01, 0.01),
              omega_param = c(1.0, 50.0, 1.0, 5.0),
              wishdf_param = 15,
              prec_logy_hyp_param = c(4.0, 1.0),
              decay_type = "exponential") |>
    expect_snapshot_value(style = "deparse")
})

test_that("Omit mu_hyp_param under power decay", {
  prep_priors(max_antigens = 2, 
              prec_hyp_param = c(0.01, 0.01, 0.01, 0.01),
              omega_param = c(1.0, 50.0, 1.0, 5.0, 1.0),
              wishdf_param = 15,
              prec_logy_hyp_param = c(4.0, 1.0)) |>
    expect_error("Need to specify 5 priors for `mu_hyp_param`")
})

test_that("Omit prec_hyp_param under power decay", {
  prep_priors(max_antigens = 2, 
              mu_hyp_param = c(1.0,  5.0, 0.0, -2.0, -1.0),
              omega_param = c(1.0, 50.0, 1.0, 5.0, 1.0),
              wishdf_param = 15,
              prec_logy_hyp_param = c(4.0, 1.0)) |>
    expect_error("Need to specify 5 priors for `prec_hyp_param`")
})

test_that("Omit omega_param under power decay", {
  prep_priors(max_antigens = 2, 
              mu_hyp_param = c(1.0,  5.0, 0.0, -2.0, -1.0),
              prec_hyp_param = c(0.01, 0.01, 0.01, 0.01, 0.01),
              wishdf_param = 15,
              prec_logy_hyp_param = c(4.0, 1.0)) |>
    expect_error("Need to specify 5 priors for `omega_param`")
})


test_that("Expect error for mu_hyp_param under exponential", {
  prep_priors(max_antigens = 2, 
              mu_hyp_param = c(1.0),
              decay_type = "exponential") |>
    expect_error("Need to specify 4 priors for `mu_hyp_param`")
})

test_that("Expect error for prec_hyp_param under exponential", {
  prep_priors(max_antigens = 2, 
              mu_hyp_param = 1:4,
              prec_hyp_param = c(0.01),
              decay_type = "exponential") |>
    expect_error("Need to specify 4 priors for `prec_hyp_param`")
})

test_that("Expect error for omega_param under exponential", {
  prep_priors(max_antigens = 2, 
              mu_hyp_param = 1:4, 
              prec_hyp_param = rep(0.01, 4),
              omega_param = c(1.0),
              decay_type = "exponential") |>
    expect_error("Need to specify 4 priors for `omega_param`")
})

test_that("Expect error for misspelling of decay type", {
  prep_priors(max_antigens = 2, 
              mu_hyp_param = c(1.0,  5.0, 0.0, -2.0),
              prec_hyp_param = c(0.01, 0.01, 0.01, 0.01),
              omega_param = c(1.0, 50.0, 1.0, 5.0),
              wishdf_param = 15,
              prec_logy_hyp_param = c(4.0, 1.0),
              decay_type = "Power") |>
    expect_error("Must specify `decay_type`")
})
