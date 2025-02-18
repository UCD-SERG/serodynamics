test_that("results are consistent", {
  
  withr::with_seed(1,
                   code = {
                     raw_data <- 
                       serocalculator::typhoid_curves_nostrat_100 |>
                       sim_case_data(n = 5) |> 
                       as_case_data(id_var = "id")   
                   })
   prepped_data <- prep_data(raw_data)
   
   expect_snapshot_value(prepped_data, style = "serialize")
  
})
