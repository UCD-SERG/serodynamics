# Basic usage: 3 biomarkers, weakly-informative defaults
pri <- prep_priors_multi_b(n_blocks = 3)
str(pri)

# Custom scales (and degrees of freedom)
pri_custom <- prep_priors_multi_b(
  n_blocks      = 4,
  omega_p_scale = c(0.2, 0.2, 0.3, 0.3, 0.4),
  nu_p          = 7,
  omega_b_scale = rep(1.5, 4),
  nu_b          = 6
)
str(pri_custom)
