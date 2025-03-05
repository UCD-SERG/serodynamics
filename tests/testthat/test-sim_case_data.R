test_that(
  desc = "results are consistent", 
  code = {
  
  withr::with_seed(1,
            code = {
              sim_data <- 
                serocalculator::typhoid_curves_nostrat_100 |>
                sim_case_data(n = 10)
            })

    expect_snapshot_value(sim_data, style = "serialize")
    
    ssdtools:::expect_snapshot_data(sim_data, name = "sim-case-data")
      
})
