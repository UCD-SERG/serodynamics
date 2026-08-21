test_that(
  desc = "results are consistent with simulated data",
  code = {
    skip_on_cran()
    skip_if_not(
      Sys.getenv("RUN_HEAVY_TESTS") == "true",
      message = "Skipping heavy JAGS test unless RUN_HEAVY_TESTS=true"
    )
    testthat::announce_snapshot_file("sim-strat-curve-params.csv")
    withr::local_seed(1)
    strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
      sim_case_data(n = 100,
                    antigen_isos = "HlyE_IgA") |>
      mutate(strat = "stratum 2")
    withr::local_seed(2)
    strat2 <- serocalculator::typhoid_curves_nostrat_100 |>
      sim_case_data(n = 100, antigen_isos = "HlyE_IgA") |>
      mutate(strat = "stratum 1")
    dataset <- dplyr::bind_rows(strat1, strat2)
    results <- run_serodynamics(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 100, # Number of adaptations to run
      nburn = 100, # Number of unrecorded samples before sampling begins
      nmc = 10,
      niter = 10, # Number of iterations
      strat = "strat", # Variable to be stratified
      with_pop_params = TRUE,
      mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
      prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
      omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
      wishdf_param = 20,
      prec_logy_hyp_param = c(4.0, 1.0)
    ) |>
      suppressWarnings()

    results |>
      dplyr::slice_head(n = 100) |>
      expect_snapshot_data(
        "sim-strat-curve-params",
        variant = darwin_variant()
      )

    # Testing exact order of attributes
    expect_equal(names(attributes(results))[1:3],
                 c("names", "row.names", "class"))

    # Testing attributes
    results |>
      attributes() |>
      names() |>
      expect_setequal(c("names", "row.names", "class", "nChains",
                        "nParameters", "nIterations", "nBurnin", "nThin",
                        "population_params", "priors",
                        "original_data", "decay_type", "strat"))

    expect_equal(attr(results, "original_data"), dataset |>
                   dplyr::select(dplyr::all_of(attr(dataset, "id_var")),
                     dplyr::all_of(attr(dataset, "biomarker_var")),
                     dplyr::all_of(attr(dataset, "timeindays")),
                     dplyr::all_of(attr(dataset, "value_var")),
                     strat
                   ))
    expect_equal(attr(results, "strat"), "strat")

    pop_params <- attributes(results)$population_params
    expect_s3_class(pop_params, "data.frame")
    expect_true(all(c("Population_Parameter", "value") %in% names(pop_params)))

    expect_setequal(
      unique(pop_params$Population_Parameter),
      c("mu.par", "prec.par", "prec.logy")
    )
    expect_true(all(is.finite(pop_params$value)))

  }
)

test_that(
  desc = "results are consistent with SEES data",
  code = {
    skip_on_cran()
    skip_if_not(
      Sys.getenv("RUN_HEAVY_TESTS") == "true",
      message = "Skipping heavy JAGS test unless RUN_HEAVY_TESTS=true"
    )
    testthat::announce_snapshot_file("strat-curve-params.csv")
    testthat::announce_snapshot_file("popparam-strat-summary-stats.csv")
    withr::local_seed(1)
    dataset <- serodynamics::nepal_sees

    results <- run_serodynamics(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 10, # Number of adaptations to run
      nburn = 10, # Number of unrecorded samples before sampling begins
      nmc = 100,
      niter = 100, # Number of iterations
      strat = "bldculres", # Variable to be stratified by
      with_post = TRUE,
      with_pop_params = TRUE,
      preclogy_per_iso = TRUE,
      mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
      prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
      omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
      wishdf_param = 20,
      prec_logy_hyp_param = c(4.0, 1.0)
    ) |>
      suppressWarnings()

    # Testing attributes
    results |>
      attributes() |>
      names() |>
      expect_setequal(c("names", "row.names", "class", "nChains", "nParameters",
                        "nIterations", "nBurnin", "nThin", "population_params",
                        "priors", "original_data", "decay_type", "strat", 
                        "jags.post"))

    expect_equal(attr(results, "original_data"), dataset  |>
                   dplyr::select(dplyr::all_of(attr(dataset, "id_var")),
                     dplyr::all_of(attr(dataset, "biomarker_var")),
                     dplyr::all_of(attr(dataset, "timeindays")),
                     dplyr::all_of(attr(dataset, "value_var")),
                     bldculres
                   ))
    expect_equal(attr(results, "strat"), "bldculres")
    
    results |>
      dplyr::slice_head(n = 100) |>
      expect_snapshot_data(
        "strat-curve-params",
        variant = darwin_variant()
      )

    # Testing for population parameters
    attributes(results)$population_params |>
      dplyr::group_by(Parameter) |>
      dplyr::summarise(
        mean = mean(value),
        sd = sd(value),
        .groups = "drop"
      ) |>
      dplyr::arrange(Parameter) |>
      expect_snapshot_data(
        "popparam-strat-summary-stats",
        variant = darwin_variant()
      )

    pop_params <- attr(results, "population_params")
    expect_s3_class(pop_params, "data.frame")

    preclogy_row <- pop_params[
      pop_params$Population_Parameter == "prec.logy",
    ]
    expect_gt(nrow(preclogy_row), 0)

    # With preclogy_per_iso = TRUE, Parameter should be the isotype label,
    # not the constant "prec.logy"
    expect_false(any(preclogy_row$Parameter == "prec.logy"))
    expect_true(all(preclogy_row$Parameter %in% unique(pop_params$Iso_type)))

    jags_post <- attributes(results)$jags.post
    expect_false(is.null(jags_post))
    expect_type(jags_post, "list")
    expect_true("typhi" %in% names(jags_post))
    expect_s3_class(jags_post$typhi$mcmc, "mcmc.list")
  }
)

test_that(
  desc = "exponential decay validates model configuration",
  code = {
    expect_error(
      run_serodynamics(
        data = data.frame(Subject = 1),
        decay_type = "exponential"
      ),
      class = "rlang_error"
    )

    expect_error(
      run_serodynamics(
        data = data.frame(Subject = 1),
        file_mod = serodynamics_example("model.jags"),
        decay_type = "exponential"
      ),
      "incompatible",
      fixed = TRUE
    )
  }
)

test_that(
  desc = "exponential decay preserves the SEES output structure",
  code = {
    skip_on_cran()
    skip_if_not(
      Sys.getenv("RUN_HEAVY_TESTS") == "true",
      message = "Skipping heavy JAGS test unless RUN_HEAVY_TESTS=true"
    )
    withr::local_seed(1)
    dataset <- serodynamics::nepal_sees

    results <- run_serodynamics(
      data = dataset, # The data set input
      decay_type = "exponential",
      nchain = 2, # Number of mcmc chains to run
      nadapt = 10, # Number of adaptations to run
      nburn = 10, # Number of unrecorded samples before sampling begins
      nmc = 100,
      niter = 100, # Number of iterations
      strat = "bldculres", # Variable to be stratified by
      with_post = TRUE,
      with_pop_params = TRUE,
      preclogy_per_iso = TRUE,
      mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
      prec_hyp_param = c(1.0, 0.00001, 1.0, 0.001, 1.0),
      omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
      wishdf_param = 20,
      prec_logy_hyp_param = c(4.0, 1.0)
    ) |>
      suppressWarnings()

    # Testing attributes
    results |>
      attributes() |>
      names() |>
      expect_setequal(c(
        "names", "row.names", "class", "nChains", "nParameters",
        "nIterations", "nBurnin", "nThin", "population_params",
        "priors", "decay_type", "original_data", "strat", "jags.post"
      ))

    expect_s3_class(results, "data.frame")
    expect_gt(nrow(results), 0)
    expect_true(all(
      c("Subject", "Parameter", "value") %in% names(results)
    ))

    used_priors <- attr(results, "priors")
    expect_length(used_priors$mu_hyp_param, 4)
    expect_length(used_priors$prec_hyp_param, 4)
    expect_length(used_priors$omega_param, 4)

    # Testing for population parameters
    pop_params <- attr(results, "population_params")
    expect_equal(attr(results, "decay_type"), "exponential")
    expect_s3_class(pop_params, "data.frame")

    shape_rows <- results |>
      dplyr::filter(.data$Parameter == "shape")
    expect_gt(nrow(shape_rows), 0)
    expect_true(all(shape_rows$value == 1))

    expect_false(any(
      grepl("shape", pop_params$Parameter, fixed = TRUE),
      na.rm = TRUE
    ))

    preclogy_row <- pop_params[
      pop_params$Population_Parameter == "prec.logy",
    ]
    expect_gt(nrow(preclogy_row), 0)

    # With preclogy_per_iso = TRUE, Parameter should be the isotype label,
    # not the constant "prec.logy"
    expect_false(any(preclogy_row$Parameter == "prec.logy"))
    expect_true(all(
      preclogy_row$Parameter %in% unique(pop_params$Iso_type)
    ))

    jags_post <- attributes(results)$jags.post
    expect_false(is.null(jags_post))
    expect_type(jags_post, "list")
    expect_true("typhi" %in% names(jags_post))
    expect_s3_class(jags_post$typhi$mcmc, "mcmc.list")

    raw_parameter_names <- colnames(
      as.matrix(jags_post$typhi$mcmc)
    )
    expect_false(any(
      startsWith(raw_parameter_names, "shape[")
    ))
  }
)

test_that(
  desc = "results consistent with unstratified SEES data",
  code = {
    skip_on_cran()
    skip_if_not(
      Sys.getenv("RUN_HEAVY_TESTS") == "true",
      message = "Skipping heavy JAGS test unless RUN_HEAVY_TESTS=true"
    )
    testthat::announce_snapshot_file("nostrat-curve-params-specpriors.csv")
    withr::local_seed(1)
    dataset <- serodynamics::nepal_sees

    results <- run_serodynamics(
      data = dataset, # The data set input
      file_mod = serodynamics_example("model.jags"),
      nchain = 2, # Number of mcmc chains to run
      nadapt = 10, # Number of adaptations to run
      nburn = 10, # Number of unrecorded samples before sampling begins
      nmc = 100,
      niter = 100, # Number of iterations
      strat = NA, # Variable to be stratified
      with_post = TRUE,
      mu_hyp_param = c(1, 4, 1, -3, -1),
      prec_hyp_param = c(0.01, 0.0001, 0.01, 0.001, 0.01),
      omega_param = c(1, 20, 1, 10, 1),
      wishdf_param = 10,
      prec_logy_hyp_param = c(3, 1)
    ) |>
      suppressWarnings()

    expect_equal(attr(results, "priors")$mu_hyp_param, c(1, 4, 1, -3, -1))
    expect_equal(attr(results, "priors")$prec_hyp_param,
                 c(0.01, 0.0001, 0.01, 0.001, 0.01))
    expect_equal(attr(results, "priors")$omega_param, c(1, 20, 1, 10, 1))
    expect_equal(attr(results, "priors")$wishdf_param, 10)
    expect_equal(attr(results, "priors")$prec_logy_hyp_param, c(3, 1))

    results |>
      dplyr::slice_head(n = 100) |>
      expect_snapshot_data(
        "nostrat-curve-params-specpriors",
        variant = darwin_variant()
      )

    expect_null(attr(results, "population_params"))

    # Testing for non-stratified jags_post
    jags_post <- attributes(results)$jags.post
    expect_false(is.null(jags_post))
    expect_type(jags_post, "list")
    expect_true("None" %in% names(jags_post))
    expect_s3_class(jags_post$None$mcmc, "mcmc.list")

  }
)
