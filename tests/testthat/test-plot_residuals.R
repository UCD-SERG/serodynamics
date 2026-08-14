
dataset <- serodynamics::nepal_sees_jags_output

testthat::test_that(
  "plot_residuals() facets by Iso_type and orders x by time with strat",
  {
    plot1 <- plot_residuals(
      model = dataset,
      ids = c("sees_npl_128", "sees_npl_131"),
      antigen_isos = c("HlyE_IgA", "HlyE_IgG")
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
      dplyr::group_by(Subject, Iso_type) |>
      dplyr::summarise(ok = all(diff(t) >= 0), .groups = "drop")
    testthat::expect_true(all(time_checks$ok))
  }
)

testthat::test_that(
  "plot_residuals() supports connect_lines, show_interval, and MAE labels",
  {
    args <- list(
      model = dataset,
      ids = c("sees_npl_128", "sees_npl_131"),
      antigen_isos = c("HlyE_IgA", "HlyE_IgG")
    )

    layer_classes <- function(p) {
      vapply(p$layers, function(l) class(l$geom)[1], character(1))
    }

    plot_default <- do.call(plot_residuals, args)
    testthat::expect_true("GeomErrorbar" %in% layer_classes(plot_default))
    testthat::expect_true("GeomText" %in% layer_classes(plot_default))
    testthat::expect_false("GeomLine" %in% layer_classes(plot_default))

    plot_custom <- do.call(
      plot_residuals,
      c(args, list(connect_lines = TRUE, show_interval = FALSE))
    )
    testthat::expect_true("GeomLine" %in% layer_classes(plot_custom))
    testthat::expect_false("GeomErrorbar" %in% layer_classes(plot_custom))
  }
)

testthat::test_that(
  "plot_residuals() only colors by Subject when ids is supplied",
  {
    plot_no_ids <- plot_residuals(model = dataset)
    plot_with_ids <- plot_residuals(
      model = dataset,
      ids = c("sees_npl_128", "sees_npl_131")
    )

    has_color <- function(p) {
      any(vapply(
        p$layers,
        function(l) !is.null(l$mapping$colour) || !is.null(l$mapping$color),
        logical(1)
      ))
    }

    testthat::expect_false(has_color(plot_no_ids))
    testthat::expect_true(has_color(plot_with_ids))
  }
)

testthat::test_that(
  "plot_residuals() uses decay_type = 'exponential' from run_serodynamics()",
  {
    # testthat::skip_on_cran()
    # testthat::skip_if_not(
    #   Sys.getenv("RUN_HEAVY_TESTS") == "true",
    #   message = "Skipping heavy JAGS test unless RUN_HEAVY_TESTS=true"
    # )
    withr::local_seed(1)
    model <- results_unstrat_exp
    testthat::expect_equal(attr(model,"decay_type"), "exponential")

    fit_res <- calc_fit_mod(
      modeled_dat = model,
      original_data = attr(model, "original_data"),
      strat = attr(model, "strat"),
      decay_type = attr(model, "decay_type")
    )

    # Regression check: when `decay_type` isn't forwarded to `ab()`, the
    # exponential curve's `shape = 1` is misapplied in the power formula,
    # which collapses `fitted` to exactly 1 for every post-peak observation.
    testthat::expect_false(any(fit_res$fitted == 1, na.rm = TRUE))

    plot_exp <- plot_residuals(model)
    testthat::expect_s3_class(plot_exp, "ggplot")
  }
)
