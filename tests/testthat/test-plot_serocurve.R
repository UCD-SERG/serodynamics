test_that(
  desc = "plot_serocurve() works with predictive param_source (default)",
  code = {
    skip_if(getRversion() < "4.4.1")

    sr_model <- serodynamics::nepal_sees_jags_output

    # Single antigen-iso, single stratum
    p1 <- plot_serocurve(
      model       = sr_model,
      antigen_iso = "HlyE_IgA",
      strat       = "typhi"
    )
    vdiffr::expect_doppelganger("serocurve-predictive-single-strat", p1)

    # Multiple strata coloured (default)
    p2 <- plot_serocurve(
      model       = sr_model,
      antigen_iso = "HlyE_IgA"
    )
    vdiffr::expect_doppelganger("serocurve-predictive-multi-strat", p2)

    # Faceted by stratification
    p3 <- plot_serocurve(
      model          = sr_model,
      antigen_iso    = "HlyE_IgA",
      facet_by_strat = TRUE
    )
    vdiffr::expect_doppelganger("serocurve-predictive-facet-strat", p3)

    # Multiple antigen-isotypes, faceted
    p4 <- plot_serocurve(
      model                = sr_model,
      antigen_iso          = c("HlyE_IgA", "HlyE_IgG"),
      facet_by_antigen_iso = TRUE
    )
    vdiffr::expect_doppelganger("serocurve-predictive-facet-antigen-iso", p4)

    # Without CI
    p5 <- plot_serocurve(
      model       = sr_model,
      antigen_iso = "HlyE_IgA",
      strat       = "typhi",
      show_ci     = FALSE
    )
    vdiffr::expect_doppelganger("serocurve-predictive-no-ci", p5)
  }
)

test_that(
  desc = "plot_serocurve() works with population param_source",
  code = {
    skip_if(getRversion() < "4.4.1")

    sr_model <- serodynamics::nepal_sees_jags_output

    p6 <- plot_serocurve(
      model        = sr_model,
      antigen_iso  = "HlyE_IgA",
      strat        = "typhi",
      param_source = "population"
    )
    vdiffr::expect_doppelganger("serocurve-population-single-strat", p6)

    # Confirm exponential population curves use a fixed shape of 1.
    exp_model <- tibble::tibble(
      Iso_type = "test",
      Stratification = "None"
    )
    attr(exp_model, "decay_type") <- "exponential"
    attr(exp_model, "population_params") <- tibble::tibble(
      Iteration = rep(1L, 4),
      Chain = rep(1L, 4),
      Parameter = c(
        "log(y0)",
        "log(y1 - y0)",
        "log(t1)",
        "log(alpha)"
      ),
      Iso_type = rep("test", 4),
      Stratification = rep("None", 4),
      Population_Parameter = rep("mu.par", 4),
      value = c(log(1), log(9), log(5), log(0.1))
    )

    exp_params <- get_serocurve_pop_params(
      exp_model,
      "test",
      "None",
      "exponential"
    )
    expect_equal(exp_params$shape, 1)

    exp_plot <- plot_serocurve(
      model = exp_model,
      antigen_iso = "test",
      strat = "None",
      param_source = "population",
      show_ci = FALSE,
      xlim = c(10, 10)
    )
    exp_curve_data <- ggplot2::layer_data(exp_plot, 1)
    expected <- ab(
      t = 10,
      y0 = 1,
      y1 = 10,
      t1 = 5,
      alpha = 0.1,
      shape = 1,
      decay_type = "exponential"
    )

    expect_equal(
      exp_curve_data$y[exp_curve_data$x == 10],
      expected
    )
  }
)

test_that(
  desc = "plot_serocurve() errors when population_params attribute is missing",
  code = {
    # Strip the population_params attribute to simulate an old sr_model object
    sr_model_old <- serodynamics::nepal_sees_jags_output
    attr(sr_model_old, "population_params") <- NULL

    expect_error(
      plot_serocurve(sr_model_old, antigen_iso = "HlyE_IgA",
                     param_source = "population"),
      regexp = "population_params"
    )
  }
)
