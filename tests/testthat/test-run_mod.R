test_that(
  desc = "results are consistent with simulated data",
  code = {
    skip_on_os(c("windows", "linux"))
    library(runjags)
    withr::local_seed(1)
    library(dplyr)
    strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
      sim_case_data(n = 100,
                    antigen_isos = "HlyE_IgA") |>
      mutate(strat = "stratum 2")
    withr::local_seed(2)
    strat2 <- serocalculator::typhoid_curves_nostrat_100 |>
      sim_case_data(n = 100,
                    antigen_isos = "HlyE_IgA") |>
      mutate(strat = "stratum 1")
    dataset <- bind_rows(strat1, strat2)
    withr::with_seed(
      1,
      code = {
        withr::local_seed(1)
        results <- run_mod(
          data = dataset, # The data set input
          file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
          nchain = 2, # Number of mcmc chains to run
          nadapt = 100, # Number of adaptations to run
          nburn = 100, # Number of unrecorded samples before sampling begins
          nmc = 10,
          niter = 10, # Number of iterations
          strat = "strat" # Variable to be stratified
        ) |>
          suppressWarnings() |>
          magrittr::use_series("curve_params")
        
        results |>
          attributes() |>
          rlist::list.remove("row.names") |>
          expect_snapshot_value(style = "deparse")
        
        results |>
          ssdtools:::expect_snapshot_data("sim-strat-curve-params")
        
      }
    )
  }
)

test_that(
  desc = "results are consistent with SEES data",
  code = {
    skip_on_os(c("windows", "linux"))
    withr::local_seed(1)
    library(runjags)
    dataset <- serodynamics::nepal_sees |>
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
      nadapt = 10, # Number of adaptations to run
      nburn = 10, # Number of unrecorded samples before sampling begins
      nmc = 100,
      niter = 100, # Number of iterations
      strat = "bldculres" # Variable to be stratified
    ) |>
      suppressWarnings() |>
      magrittr::use_series("curve_params")

    results |>
      attributes() |>
      rlist::list.remove("row.names") |>
      expect_snapshot_value(style = "deparse")

    results |>
      ssdtools:::expect_snapshot_data("strat-curve-params")
  }
)

test_that(
  desc = "results are consistent with unstratified SEES data",
  code = {
    skip_on_os(c("windows", "linux"))
    withr::local_seed(1)
    library(runjags)
    dataset <- serodynamics::nepal_sees |>
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
      nadapt = 10, # Number of adaptations to run
      nburn = 10, # Number of unrecorded samples before sampling begins
      nmc = 100,
      niter = 100, # Number of iterations
      strat = NA # Variable to be stratified
    ) |>
      suppressWarnings() |>
      magrittr::use_series("curve_params")

    results |>
      attributes() |>
      rlist::list.remove("row.names") |>
      expect_snapshot_value(style = "deparse")

    results |>
      ssdtools:::expect_snapshot_data("nostrat-curve-params")
  }
)
