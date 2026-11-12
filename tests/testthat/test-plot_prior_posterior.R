
# ---------------------------------------------------------
# Basic output
# ---------------------------------------------------------

test_that("plot_prior_posterior returns a ggplot and has distributions", {
  withr::local_seed(1)
  p <- plot_prior_posterior(
    nepal_sees_jags_output,
    n_prior = 100
  )
  
  expect_s3_class(p, "ggplot")
  
  dat <- attr(p, "predictive_data")
  
  expect_true(is.data.frame(dat))
  
  # Making sure distributions are there
  expect_setequal(
    as.character(unique(dat$Distribution)),
    c(
      "Prior predictive",
      "Posterior predictive"
    )
  )
  
  # Making sure parameters are there
  expect_setequal(
    as.character(unique(dat$Parameter)),
    c("y0", "y1", "t1", "alpha", "shape")
  )
})


# ---------------------------------------------------------
# Prior predictive sampling
# ---------------------------------------------------------

test_that("prior predictive draws are reproducible", {
  withr::local_seed(1)
  model <- make_test_model()
  
  p1 <- plot_prior_posterior(
    model,
    n_prior = 200
  )
  
  p2 <- plot_prior_posterior(
    model,
    n_prior = 200
  )
  
  dat1 <- attr(p1, "predictive_data")
  dat2 <- attr(p2, "predictive_data")
  
  prior1 <- dat1[
    dat1$Distribution == "Prior predictive",
  ]
  
  prior2 <- dat2[
    dat2$Distribution == "Prior predictive",
  ]
  
  expect_equal(prior1, prior2)
})


test_that("n_prior controls number of prior draws", {
  
  model <- make_test_model()
  
  n_prior <- 150
  
  p <- plot_prior_posterior(
    model,
    n_prior = n_prior,
    seed = 123
  )
  
  dat <- attr(p, "predictive_data")
  
  prior <- dat[
    dat$Distribution == "Prior predictive",
  ]
  
  counts <- prior |>
    dplyr::count(
      Iso_type,
      Stratification,
      Parameter
    )
  
  expect_true(all(counts$n == n_prior))
})


test_that("prior predictive parameters satisfy constraints", {
  withr::local_seed(1)
  model <- make_test_model()
  
  p <- plot_prior_posterior(
    model,
    n_prior = 200
  )
  
  dat <- attr(p, "predictive_data")
  
  prior <- dat[
    dat$Distribution == "Prior predictive",
  ]
  
  expect_true(all(prior$value > 0))
  
  shape <- prior[
    prior$Parameter == "shape",
  ]
  
  expect_true(all(shape$value > 1))
})


# ---------------------------------------------------------
# Posterior predictive extraction
# ---------------------------------------------------------

test_that("posterior predictive values are preserved", {
  
  model <- make_test_model()
  
  p <- plot_prior_posterior(
    model,
    n_prior = 100,
    seed = 123
  )
  
  dat <- attr(p, "predictive_data")
  
  posterior <- dat[
    dat$Distribution == "Posterior predictive",
  ]
  
  expect_equal(
    nrow(posterior),
    nrow(as.data.frame(model))
  )
  
  expect_equal(
    sort(posterior$value),
    sort(as.data.frame(model)$value)
  )
})


# ---------------------------------------------------------
# Filtering
# ---------------------------------------------------------

test_that("iso filtering works", {
  
  model <- make_test_model()
  
  p <- plot_prior_posterior(
    model,
    iso = "Ogawa",
    n_prior = 100,
    seed = 123
  )
  
  dat <- attr(p, "predictive_data")
  
  expect_setequal(
    unique(dat$Iso_type),
    "Ogawa"
  )
})


test_that("parameter filtering works", {
  
  model <- make_test_model()
  
  p <- plot_prior_posterior(
    model,
    param = c("y0", "y1"),
    n_prior = 100,
    seed = 123
  )
  
  dat <- attr(p, "predictive_data")
  
  expect_setequal(
    as.character(unique(dat$Parameter)),
    c("y0", "y1")
  )
})


test_that("stratification filtering works", {
  
  model <- make_test_model()
  
  p <- plot_prior_posterior(
    model,
    strat = "Infection",
    n_prior = 100,
    seed = 123
  )
  
  dat <- attr(p, "predictive_data")
  
  expect_setequal(
    unique(dat$Stratification),
    "Infection"
  )
})


test_that("invalid selection produces informative error", {
  
  model <- make_test_model()
  
  expect_error(
    plot_prior_posterior(
      model,
      iso = "Nonexistent",
      n_prior = 100
    ),
    "No posterior predictive draws"
  )
})


# ---------------------------------------------------------
# Plotting options
# ---------------------------------------------------------

test_that("log_x applies logarithmic scale", {
  
  model <- make_test_model()
  
  p <- plot_prior_posterior(
    model,
    n_prior = 100,
    log_x = TRUE,
    seed = 123
  )
  
  yscale <- p$scales$get_scales("x")
  
  expect_false(is.null(yscale))
  
  expect_match(
    yscale$trans$name,
    "log"
  )
})


test_that("facet scales are configurable", {
  
  model <- make_test_model()
  
  p <- plot_prior_posterior(
    model,
    n_prior = 100,
    facet_scales = "free_y",
    seed = 123
  )
  
  expect_true(p$facet$params$free$y)
  expect_false(p$facet$params$free$x)
})


# ---------------------------------------------------------
# Input validation
# ---------------------------------------------------------

test_that("missing priors produces an error", {
  
  model <- make_test_model()
  
  attr(model, "priors") <- NULL
  
  expect_error(
    plot_prior_posterior(
      model,
      n_prior = 100
    ),
    "prior"
  )
})


test_that("posterior predictions must exist", {
  
  model <- make_test_model()
  
  model$Subject <- "observed"
  
  expect_error(
    plot_prior_posterior(
      model,
      n_prior = 100
    ),
    "No posterior predictive draws"
  )
})
