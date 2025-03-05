set.seed(1)
sim_case_data <-
  serocalculator::typhoid_curves_nostrat_100 |>
  sim_case_data(n = 5, max_n_obs = 20, followup_interval = 14)

sim_case_data |>
  autoplot(alpha = .5)
