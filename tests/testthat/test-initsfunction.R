test_that("results are consistent", {
  initsfunction(c(4, 1, 3, 2)) |> expect_snapshot_value(style = "deparse")
})

test_that("chain inits keep the power-decay recovery term positive", {
  withr::local_seed(123)
  simulated_data <- sim_case_data(
    n = 5,
    curve_params = serocalculator::typhoid_curves_nostrat_100,
    max_n_obs = 6,
    followup_interval = 14
  )
  longdata <- prep_data(simulated_data)

  init_values <- build_chain_inits(longdata, chain = 1, n_params = 5L)

  expect_named(init_values, c(".RNG.seed", ".RNG.name", "par"))
  expect_equal(
    dim(init_values$par),
    c(longdata$nsubj, longdata$n_antigen_isos, 5)
  )
  expect_true(all(is.finite(init_values$par)))

  y0 <- exp(init_values$par[, , 1])
  y1 <- y0 + exp(init_values$par[, , 2])
  t1 <- exp(init_values$par[, , 3])
  alpha <- exp(init_values$par[, , 4])
  shape <- exp(init_values$par[, , 5]) + 1

  for (subj in seq_len(longdata$nsubj)) {
    observed_times <- longdata$smpl.t[subj, ]
    observed_times <- observed_times[is.finite(observed_times)]

    for (obs_time in observed_times) {
      expect_true(all(
        y1[subj, ]^(1 - shape[subj, ]) -
          (1 - shape[subj, ]) * alpha[subj, ] * (obs_time - t1[subj, ])
          > 0
      ))
    }
  }
})

test_that("runjags initializes with explicit par starts", {
  skip_on_cran()
  skip_if_not_installed("rjags")
  skip_if_not_installed("runjags")

  withr::local_seed(123)
  simulated_data <- sim_case_data(
    n = 3,
    curve_params = serocalculator::typhoid_curves_nostrat_100,
    max_n_obs = 3,
    followup_interval = 14
  )
  longdata <- prep_data(simulated_data)
  priors <- prep_priors(max_antigens = longdata$n_antigen_isos)
  chain_inits <- function(chain) {
    return(build_chain_inits(longdata, chain, priors$n_params))
  }
  init_values <- chain_inits(1)

  expect_named(init_values, c(".RNG.seed", ".RNG.name", "par"))
  expect_equal(
    dim(init_values$par),
    c(longdata$nsubj, longdata$n_antigen_isos, priors$n_params)
  )
  expect_equal(init_values$par[, , 4], array(-10, dim(init_values$par)[1:2]))
  expect_equal(init_values$par[, , 5], array(-10, dim(init_values$par)[1:2]))

  expect_no_error(
    runjags::run.jags(
      model = serodynamics_example("model.jags"),
      data = c(longdata, priors),
      inits = chain_inits,
      method = "rjags",
      adapt = 0,
      burnin = 0,
      thin = 1,
      sample = 1,
      n.chains = 1,
      monitor = "y0",
      summarise = FALSE
    ) |>
      suppressWarnings()
  )
})

test_that(
  desc = "runjags results are consistent", 
  code = {
    skip_on_cran()
    skip_if_not(
      Sys.getenv("RUN_HEAVY_TESTS") == "true",
      message = "Skipping heavy JAGS test unless RUN_HEAVY_TESTS=true"
    )
    set.seed(1)
    data1 <- rbinom(n = 91, size = 1, prob = .6)
    jags_post0 <- run.jags(
      n.chains = 2,
      inits = initsfunction,
      method = "parallel",
      model = serodynamics_example("model.dobson.jags"),
      data = list(r = data1, N = length(data1)),
      monitor = "p",
      sample = 10
    ) |> suppressWarnings()
    
    jags_unpack <- ggmcmc::ggs(jags_post0[["mcmc"]])
    
    jags_unpack |> expect_snapshot_data("dobson")
    
  }
)
