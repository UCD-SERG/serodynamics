test_that("results are consistent", {
  
  case_data <-
    serodynamics_example(
      "SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv"
    ) |>
    readr::read_csv() |>
    dplyr::mutate(
      .by = person_id,
      visit_num = dplyr::row_number()
    ) |>
    as_case_data(
      id_var = "person_id",
      biomarker_var = "antigen_iso",
      value_var = "result",
      time_in_days = "dayssincefeveronset"
    )
  
  case_data |> 
    autoplot(alpha = .5, log_x = FALSE) |> 
    vdiffr::expect_doppelganger(title = "case-data-plot")
    
  
  
})
