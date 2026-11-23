
pp <- prior_predict(
  mu_hyp_param = c(0.5, 5, 2, -2, -3),
  prec_hyp_param = rep(1, 5),
  omega_param = c(1, 5, 1, 5, 1),
  wishdf_param = 20,
  prec_logy_hyp_param = c(4, 1),
  n = 500,
  type = "curves"
)

pp
summary(pp)

prior_predict(
  mu_hyp_param = c(0.5, 5, 2, -2, -3),
  prec_hyp_param = rep(1, 5),
  omega_param = c(1, 5, 1, 5, 1),
  wishdf_param = 20,
  prec_logy_hyp_param = c(4, 1),
  n = 1000,
  type = "density"
)
