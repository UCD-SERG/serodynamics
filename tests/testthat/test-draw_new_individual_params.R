# No JAGS fit is needed here:
# these functions take a data frame and return a data frame,
# so `population_params` is built by hand
# and the tests run in milliseconds without `RUN_HEAVY_TESTS`.

# Parameter labels as produced by `unpack_jags()` for power decay.
# These are stated rather than derived from the package,
# so that a change to the parameter set fails the test
# instead of silently redefining what it checks.
power_par_names <- c(
  "log(y0)",
  "log(y1 - y0)",
  "log(t1)",
  "log(alpha)",
  "log(shape - 1)"
)

# Tridiagonal and diagonally dominant,
# so it is symmetric positive definite for any number of parameters.
build_example_precision <- function(par_names) {
  n_par <- length(par_names)
  precision <- diag(2, nrow = n_par)
  precision[abs(row(precision) - col(precision)) == 1] <- 0.5
  dimnames(precision) <- list(par_names, par_names)
  
  return(precision)
}

# Builds the layout `run_serodynamics()` attaches
# when `with_pop_params = TRUE`.
build_pop_params <- function(mu, # Named vector; names give the parameter order
                             prec, # Precision matrix in that same order
                             n_iter = 2L,
                             n_chain = 2L,
                             iso_types = "HlyE_IgA",
                             strata = "stratum 1") {
  par_names <- names(mu)
  
  # `unpack_jags()` pastes the two indices of `prec.par` into one label.
  precision_labels <- as.vector(
    outer(par_names, par_names, paste, sep = ", ")
  )
  
  mean_block <- tibble::tibble(
    Parameter = par_names,
    Population_Parameter = "mu.par",
    value = unname(mu)
  )
  
  precision_block <- tibble::tibble(
    Parameter = precision_labels,
    Population_Parameter = "prec.par",
    value = as.vector(prec)
  )
  
  draw_keys <- tidyr::expand_grid(
    Iteration = seq_len(n_iter),
    Chain = seq_len(n_chain),
    Iso_type = iso_types,
    Stratification = strata
  )
  
  pop_params <- tidyr::expand_grid(
    draw_keys,
    dplyr::bind_rows(mean_block, precision_block)
  )
  
  return(pop_params)
}

test_that(
  desc = "draws have one row per parameter per posterior draw",
  code = {
    par_means <- stats::setNames(c(1, 4, 0.7, -6.5, -0.5), power_par_names)
    pop_params <- build_pop_params(
      par_means,
      build_example_precision(power_par_names)
    )
    
    withr::local_seed(1)
    new_params <- draw_new_individual_params(pop_params)
    
    # Testing dimensions: two iterations by two chains
    expect_equal(nrow(new_params), length(par_means) * 4L)
    
    # Testing output columns
    expect_setequal(
      names(new_params),
      c(
        "Iteration", "Chain", "Iso_type", "Stratification",
        "Parameter", "value"
      )
    )
    
    expect_setequal(unique(new_params$Parameter), power_par_names)
    expect_false(anyNA(new_params$value))
  }
)

test_that(
  desc = "parameter order follows mu.par rather than a fixed set",
  code = {
    # Exponential decay has no `shape`,
    # and this order is deliberately not the order used for power decay.
    par_names <- c("log(t1)", "log(y0)", "log(alpha)", "log(y1 - y0)")
    par_means <- stats::setNames(c(0.7, 1, -6.5, 4), par_names)
    pop_params <- build_pop_params(
      par_means,
      build_example_precision(par_names),
      n_iter = 1L,
      n_chain = 1L
    )
    
    withr::local_seed(1)
    new_params <- draw_new_individual_params(pop_params)
    
    expect_equal(new_params$Parameter, par_names)
  }
)

test_that(
  desc = "each posterior draw of each group is sampled separately",
  code = {
    par_means <- stats::setNames(c(1, 4, 0.7, -6.5, -0.5), power_par_names)
    pop_params <- build_pop_params(
      par_means,
      build_example_precision(power_par_names),
      n_iter = 2L,
      n_chain = 1L,
      iso_types = c("HlyE_IgA", "HlyE_IgG"),
      strata = c("stratum 1", "stratum 2")
    )
    
    withr::local_seed(1)
    new_params <- draw_new_individual_params(pop_params)
    
    draw_keys <-
      new_params |>
      dplyr::distinct(Iteration, Chain, Iso_type, Stratification)
    
    # Testing that isotype and stratification split the draws
    expect_equal(nrow(draw_keys), 8L)
    expect_equal(nrow(new_params), 8L * length(par_means))
    
    # Testing that draws are independent rather than recycled across groups
    expect_gt(
      dplyr::n_distinct(new_params$value),
      nrow(new_params) - 1L
    )
  }
)

test_that(
  desc = "n_draws limits how many posterior draws are used",
  code = {
    par_means <- stats::setNames(c(1, 4, 0.7, -6.5, -0.5), power_par_names)
    pop_params <- build_pop_params(
      par_means,
      build_example_precision(power_par_names)
    )
    
    withr::local_seed(1)
    new_params <- draw_new_individual_params(pop_params, n_draws = 2L)
    
    expect_equal(nrow(new_params), 2L * length(par_means))
  }
)

test_that(
  desc = "n_draws applies within each isotype and stratification group",
  code = {
    par_means <- stats::setNames(c(1, 4, 0.7, -6.5, -0.5), power_par_names)
    pop_params <- build_pop_params(
      par_means,
      build_example_precision(power_par_names),
      n_iter = 3L,
      n_chain = 1L,
      iso_types = c("HlyE_IgA", "HlyE_IgG"),
      strata = c("stratum 1", "stratum 2")
    )
    
    withr::local_seed(1)
    new_params <- draw_new_individual_params(pop_params, n_draws = 2L)
    
    draws_per_group <-
      new_params |>
      dplyr::distinct(Iteration, Chain, Iso_type, Stratification) |>
      dplyr::count(Iso_type, Stratification)
    
    # Testing that every group keeps its own n_draws
    expect_equal(nrow(draws_per_group), 4L)
    expect_true(all(draws_per_group$n == 2L))
  }
)

test_that(
  desc = "draws recover the population mean and covariance",
  code = {
    par_means <- stats::setNames(c(1, 4, 0.7, -6.5, -0.5), power_par_names)
    precision <- build_example_precision(power_par_names)
    pop_params <- build_pop_params(
      par_means,
      precision,
      n_iter = 400L,
      n_chain = 1L
    )
    
    withr::local_seed(1)
    new_params <- draw_new_individual_params(pop_params)
    
    summaries <-
      new_params |>
      dplyr::summarise(
        mean = mean(value),
        sd = stats::sd(value),
        .by = "Parameter"
      )
    
    # Sampling from the precision matrix should reproduce its inverse
    expected_sd <- sqrt(diag(solve(precision)))
    
    # Tolerance is roughly six standard errors at 400 draws
    expect_lt(max(abs(summaries$mean - unname(par_means))), 0.25)
    expect_lt(max(abs(summaries$sd - unname(expected_sd))), 0.25)
  }
)

test_that(
  desc = "missing columns are reported",
  code = {
    par_means <- stats::setNames(c(1, 4, 0.7, -6.5, -0.5), power_par_names)
    pop_params <-
      build_pop_params(
        par_means,
        build_example_precision(power_par_names)
      ) |>
      dplyr::select(-"Population_Parameter")
    
    expect_error(
      draw_new_individual_params(pop_params),
      regexp = "Population_Parameter"
    )
  }
)

test_that(
  desc = "a non-positive-definite precision matrix is rejected",
  code = {
    par_means <- stats::setNames(c(1, 4, 0.7, -6.5, -0.5), power_par_names)
    precision <- build_example_precision(power_par_names)
    precision[1, 1] <- -1 # Breaks positive definiteness
    pop_params <- build_pop_params(
      par_means,
      precision,
      n_iter = 1L,
      n_chain = 1L
    )
    
    expect_error(
      draw_new_individual_params(pop_params),
      regexp = "definite"
    )
  }
)

test_that(
  desc = "rebuild_prec_matrix inverts the label encoding used by unpack_jags",
  code = {
    precision <- build_example_precision(power_par_names)
    par_means <- stats::setNames(
      rep(0, length(power_par_names)), power_par_names
    )
    
    precision_rows <-
      build_pop_params(par_means, precision, n_iter = 1L, n_chain = 1L) |>
      dplyr::filter(Population_Parameter == "prec.par")
    
    rebuilt <- rebuild_prec_matrix(
      precision_rows,
      par_names = power_par_names
    )
    
    expect_equal(rebuilt, precision)
    expect_true(isSymmetric(rebuilt))
  }
)

test_that(
  desc = "rebuild_prec_matrix rejects malformed input",
  code = {
    precision <- build_example_precision(power_par_names)
    par_means <- stats::setNames(
      rep(0, length(power_par_names)), power_par_names
    )
    
    precision_rows <-
      build_pop_params(par_means, precision, n_iter = 1L, n_chain = 1L) |>
      dplyr::filter(Population_Parameter == "prec.par")
    
    # Testing that a short matrix is caught
    expect_error(
      rebuild_prec_matrix(
        precision_rows[-1, ],
        par_names = power_par_names
      ),
      regexp = "entries"
    )
    
    # Testing that a label without the separator is caught
    unsplittable <- precision_rows
    unsplittable$Parameter[1] <- "log(y0)"
    
    expect_error(
      rebuild_prec_matrix(unsplittable, par_names = power_par_names),
      regexp = "split"
    )
    
    # Testing that a label naming an unknown parameter is caught
    relabelled <- precision_rows
    relabelled$Parameter[1] <- "log(y0), log(not_a_parameter)"
    
    expect_error(
      rebuild_prec_matrix(relabelled, par_names = power_par_names),
      regexp = "mu.par"
    )
  }
)
