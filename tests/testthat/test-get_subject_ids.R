test_that("results are consistent", {
  
  case_data <- 
    serocalculator::typhoid_curves_nostrat_100 |>
     sim_case_data(n = 10, max_n_obs = 20, followup_interval = 14)
  
  get_subject_ids(case_data)
  
})
