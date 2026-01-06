test_that(
  desc = "results are consistent",
  code = {
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
    prepped_data <- prep_data(case_data)

    expect_snapshot_value(prepped_data, style = "serialize")
  }
)

test_that(
  desc = "results are consistent 2",
  code = {
    withr::local_package("runjags")
    set.seed(1)
    withr::local_package("dplyr")
    strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
      sim_case_data(n = 20, antigen_isos = "HlyE_IgA") |>
      mutate(strat = "stratum 2")
    longdata <- prep_data(strat1, add_newperson = FALSE)
    longdata |> expect_snapshot_value(style = "serialize")
  }
)
