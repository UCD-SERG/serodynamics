test_that(
  desc = "results are consistent",
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
      expect_snapshot_value(style = "deparse")
  }
)
