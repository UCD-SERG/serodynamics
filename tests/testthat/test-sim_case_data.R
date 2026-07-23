test_that(
  desc = "results are consistent", 
  code = {
    
    withr::with_seed(
      1,
      code = {
        sim_data <- 
          serocalculator::typhoid_curves_nostrat_100 |>
          sim_case_data(n = 10)
      }
    )
    
    expect_snapshot_value(sim_data, style = "serialize")
    
    expect_snapshot_data(sim_data, name = "sim-case-data")
    
  }
)

test_that(
  desc = "measurement error is multiplicative on the log scale",
  code = {

    noise <- c(0.29, 0.31)

    withr::with_seed(
      2,
      code = {
        clean <-
          serocalculator::typhoid_curves_nostrat_100 |>
          sim_case_data(n = 60, max_n_obs = 8)
      }
    )

    withr::with_seed(
      2,
      code = {
        noisy <-
          serocalculator::typhoid_curves_nostrat_100 |>
          sim_case_data(n = 60, max_n_obs = 8, noise_sd = noise)
      }
    )

    # noise_sd = 0 must not touch the RNG, so the two runs share a skeleton
    expect_identical(clean$id, noisy$id)
    expect_identical(clean$timeindays, noisy$timeindays)
    expect_identical(clean$iter, noisy$iter)

    expect_true(all(noisy$value > 0))

    log_ratio <- log(noisy$value) - log(clean$value)
    isos <- unique(as.character(noisy$antigen_iso))

    for (i in seq_along(isos)) {
      expect_equal(
        sd(log_ratio[noisy$antigen_iso == isos[i]]),
        noise[i],
        tolerance = 0.1
      )
    }

    # multiplicative, not additive: the log ratio does not track the level
    expect_lt(abs(cor(log_ratio, log(clean$value))), 0.1)

  }
)

test_that(
  desc = "noise_sd = 0 reproduces the noise-free simulation exactly",
  code = {

    withr::with_seed(
      3,
      code = {
        a <-
          serocalculator::typhoid_curves_nostrat_100 |>
          sim_case_data(n = 20)
      }
    )

    withr::with_seed(
      3,
      code = {
        b <-
          serocalculator::typhoid_curves_nostrat_100 |>
          sim_case_data(n = 20, noise_sd = 0)
      }
    )

    expect_identical(a, b)

  }
)

test_that(
  desc = "noise_sd is validated and can be named by isotype",
  code = {

    curves <- serocalculator::typhoid_curves_nostrat_100
    isos <- get_biomarker_levels(curves)

    expect_error(
      sim_case_data(n = 5, curve_params = curves, noise_sd = -1),
      regexp = "non-negative"
    )

    expect_error(
      sim_case_data(
        n = 5,
        curve_params = curves,
        noise_sd = rep(0.1, length(isos) + 1)
      ),
      regexp = "length"
    )

    named <- stats::setNames(seq_along(isos) / 10, rev(isos))

    withr::with_seed(
      4,
      code = {
        sim_data <-
          curves |>
          sim_case_data(n = 10, noise_sd = named)
      }
    )

    expect_identical(
      unname(attr(sim_data, "noise_sd")),
      unname(named[isos])
    )

  }
)
