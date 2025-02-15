test_that(
  desc = "results are consistent",
  code = {

    jags_output <- readr::read_rds(
      file = test_path("fixtures", "example_runjags_output.rds")
    )

    curve_params <- jags_output |> postprocess_jags_output(
      ids = attr(prepped_data, "ids"),
      antigen_isos = attr(prepped_data, "antigens")
    )

    curve_params |> ssdtools:::expect_snapshot_data(name = "curve-params")
  }
)
