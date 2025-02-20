test_that(
  desc = "results are consistent with simulated data",
  code = {
    withr::with_seed(
      1,
      code = {
        test_obj <-
          serocalculator::typhoid_curves_nostrat_100 |>
          sim_case_data(n = 5)
      }
    )

    test_obj <- test_obj |>
      as_case_data(
        id_var = "id",
        biomarker_var = "antigen_iso",
        time_in_days = "timeindays",
        value_var = "value"
      )

    test_obj |>
      attributes() |>
      listr::list_remove("row.names") |>
      expect_snapshot_value(style = "deparse")
    
    test_obj |> ssdtools:::expect_snapshot_data(name = "sim-data")
  }
)

test_that(
  desc = "results are consistent with SEES data",
  code = {
    
    
    dataset <- serodynamics_example(
      "SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv"
    ) |>
      readr::read_csv() |>
      as_case_data(
        id_var = "person_id",
        biomarker_var = "antigen_iso",
        value_var = "result",
        time_in_days = "dayssincefeveronset"
      )
    
    dataset |>
      attributes() |>
      listr::list_remove("row.names") |>
      expect_snapshot_value(style = "deparse")
    
    dataset |> ssdtools:::expect_snapshot_data(name = "sees-data")
  }
)
