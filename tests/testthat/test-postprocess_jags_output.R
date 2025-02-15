test_that(
  desc = "results are consistent",
  code = {

    jags_output <- readr::read_rds(
      file = test_path("fixtures", "example_runjags_output.rds")
    )

    curve_params <- jags_output |> postprocess_jags_output(
      ids = attr(jags_output, "ids"),
      antigen_isos = attr(jags_output, "antigen_isos")
    )

    curve_params |> ssdtools:::expect_snapshot_data(name = "curve-params")
  }
)
