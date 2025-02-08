test_that(
  desc = "results are consistent",
  code = {
    withr::with_seed(
      seed = 1,
      code = {
        test_obj <-
          set.seed(1)
        serocalculator::typhoid_curves_nostrat_100 |>
          sim_case_data(n = 100) |>
          as_case_data(
            id_var = "index_id",
            biomarker_var = "antigen_iso",
            time_in_days = "timeindays",
            value_var = "value"
          )
      }
    )

    test_obj |>
      expect_snapshot_value(style = "deparse")
  }
)
