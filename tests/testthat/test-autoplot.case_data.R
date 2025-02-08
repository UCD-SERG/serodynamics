test_that("results are consistent", {
  
  withr::with_seed(
    1,
    code = {
      case_data <- serocalculator::typhoid_curves_nostrat_100 |>
        sim_case_data(n = 10, max_n_obs = 20, followup_interval = 14)
      })
  
  case_data |> 
    autoplot(alpha = .5) |> 
    vdiffr::expect_doppelganger(title = "case-data-plot")
    
  
  
})
