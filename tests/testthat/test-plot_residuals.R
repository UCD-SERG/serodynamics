testthat::test_that(
  "plot_residuals() facets by Iso_type and orders x by time",
  {
    plot1 <- plot_residuals(
      model = serodynamics::nepal_sees_jags_output,
      dataset = serodynamics::nepal_sees,
      ids = c("sees_npl_128", "sees_npl_131"),
      antigen_isos = c("HlyE_IgA", "HlyE_IgG"),
      n_draws = 25
    )

    testthat::expect_s3_class(plot1, "ggplot")
    testthat::expect_s3_class(plot1$facet, "FacetWrap")

    plot_data <- plot1$data
    testthat::expect_true(all(c("t", "Iso_type") %in% names(plot_data)))
    testthat::expect_setequal(
      unique(plot_data$Iso_type),
      c("HlyE_IgA", "HlyE_IgG")
    )

    time_checks <- plot_data |>
      dplyr::group_by(.data$Subject, .data$Iso_type) |>
      dplyr::summarise(ok = all(diff(.data$t) >= 0), .groups = "drop")
    testthat::expect_true(all(time_checks$ok))
  }
)
