test_that(
  desc = "results are consistent",
  code = {
    set.seed(1)
    library(runjags)
    dataset <- serodynamics_example(
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

    results <- run_mod(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 100, # Number of adaptations to run
      nburn = 100, # Number of unrecorded samples before sampling begins
      nmc = 10,
      niter = 10, # Number of iterations
      strat = "bldculres" # Variable to be stratified
    ) |>
      suppressWarnings() |>
      magrittr::use_series("curve_params")

    results |>
      expect_snapshot_value(style = "serialize")

    results |>
      ssdtools:::expect_snapshot_data("strat-curve-params")
  }
)

test_that(
  desc = "results are consistent without stratification",
  code = {
    set.seed(1)
    library(runjags)
    dataset <- serodynamics_example(
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

    results <- run_mod(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 100, # Number of adaptations to run
      nburn = 100, # Number of unrecorded samples before sampling begins
      nmc = 10,
      niter = 10, # Number of iterations
      strat = NA # Variable to be stratified
    ) |>
      suppressWarnings() |>
      magrittr::use_series("curve_params")

    results |>
      expect_snapshot_value(style = "serialize")

    results |>
      ssdtools:::expect_snapshot_data("nostrat-curve-params")
  }
)
