
prep_priors_stan(max_antigens = 2,
                 mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
                 prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
                 omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
                 wishdf_param = 20,
                 prec_logy_hyp_param = c(4.0, 1.0))

prep_priors_stan(max_antigens = 2)
