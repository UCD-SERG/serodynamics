set.seed(1)
strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
  sim_case_data(n = 9, antigen_isos = "HlyE_IgA") |>
  mutate(strat = "stratum 2")
longdata <- prep_data(strat1, add_newperson = FALSE)
priors <- prep_priors(max_antigens = longdata$n_antigen_isos,
                      mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
                      prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
                      omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
                      wishdf_param = 20,
                      prec_logy_hyp_param = c(4.0, 1.0))

tomonitor <- c("y0", "y1", "t1", "alpha", "shape")

old <- 
  readr::read_rds(
    testthat::test_path("fixtures", "example_runjags_inputs.rds")
  )

print(all.equal(longdata, old))

longdata |> 
  readr::write_rds(
    testthat::test_path("fixtures", "example_runjags_inputs.rds")
  )
