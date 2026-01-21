#' Simulate antibody trajectories from priors only
#'
#' @description
#' Performs a prior predictive check by simulating antibody trajectories and
#' measurements using only the prior distributions, before fitting the model
#' to data. This is useful for assessing whether priors generate realistic
#' antibody values for a given pathogen and assay.
#'
#' @details
#' This function:
#' 1. Draws kinetic parameters from the prior distributions specified by
#'    `prep_priors()`
#' 2. Generates latent antibody trajectories using the same within-host antibody
#'    model used in the JAGS model
#' 3. Applies measurement noise to simulate observed antibody values
#' 4. Preserves the original dataset structure (IDs, biomarkers, timepoints)
#'
#' The simulation follows the hierarchical model structure:
#' - Population-level parameters are drawn from hyperpriors
#' - Individual-level parameters are drawn from population distributions
#' - Observations are generated with log-normal measurement error
#'
#' @param prepped_data A `prepped_jags_data` object from [prep_data()]
#' @param prepped_priors A `curve_params_priors` object from [prep_priors()]
#' @param n_sims [integer] Number of prior predictive simulations to generate
#' (default = 1). If > 1, returns a list of simulated datasets.
#' @param seed [integer] Optional random seed for reproducibility
#'
#' @returns If `n_sims = 1`, a `prepped_jags_data` object with simulated
#' antibody values replacing the observed values. If `n_sims > 1`, a [list]
#' of such objects.
#'
#' @export
#' @examples
#' # Prepare data and priors
#' set.seed(1)
#' raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 5)
#' prepped_data <- prep_data(raw_data)
#' prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)
#'
#' # Simulate from priors
#' sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)
#'
#' # Generate multiple simulations
#' sim_list <- simulate_prior_predictive(
#'   prepped_data, prepped_priors, n_sims = 10
#' )
simulate_prior_predictive <- function(prepped_data,
                                      prepped_priors,
                                      n_sims = 1,
                                      seed = NULL) {
  # Input validation
  if (!inherits(prepped_data, "prepped_jags_data")) {
    cli::cli_abort(
      c(
        "{.arg prepped_data} must be a {.cls prepped_jags_data}",
        "object from {.fn prep_data}"
      )
    )
  }

  if (!inherits(prepped_priors, "curve_params_priors")) {
    cli::cli_abort(
      c(
        "{.arg prepped_priors} must be a {.cls curve_params_priors}",
        "object from {.fn prep_priors}"
      )
    )
  }

  if (prepped_data$n_antigen_isos != nrow(prepped_priors$mu.hyp)) {
    cli::cli_abort(
      c(
        "Mismatch between data and priors:",
        "i" = paste(
          "{.arg prepped_data} has",
          "{prepped_data$n_antigen_isos} biomarkers"
        ),
        "i" = paste(
          "{.arg prepped_priors} is configured for",
          "{nrow(prepped_priors$mu.hyp)} biomarkers"
        )
      )
    )
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }

  # Generate simulations
  if (n_sims == 1) {
    return(simulate_one_prior_predictive(prepped_data, prepped_priors))
  } else {
    return(
      lapply(seq_len(n_sims), function(i) {
        simulate_one_prior_predictive(prepped_data, prepped_priors)
      })
    )
  }
}

#' Simulate a single prior predictive dataset
#'
#' @param prepped_data A `prepped_jags_data` object from [prep_data()]
#' @param prepped_priors A `curve_params_priors` object from [prep_priors()]
#'
#' @returns A `prepped_jags_data` object with simulated antibody values
#' @noRd
simulate_one_prior_predictive <- function(prepped_data, prepped_priors) {
  # Extract dimensions
  nsubj <- prepped_data$nsubj
  n_antigen_isos <- prepped_data$n_antigen_isos
  n_params <- prepped_priors$n_params

  # Initialize arrays for parameters
  mu_par <- array(NA, dim = c(n_antigen_isos, n_params))
  prec_par <- array(NA, dim = c(n_antigen_isos, n_params, n_params))
  prec_logy <- numeric(n_antigen_isos)

  # Sample hyperparameters for each biomarker
  for (k in seq_len(n_antigen_isos)) {
    # Sample population-level mean parameters from hyperpriors
    mu_par[k, ] <- MASS::mvrnorm(
      n = 1,
      mu = prepped_priors$mu.hyp[k, ],
      Sigma = solve(prepped_priors$prec.hyp[k, , ])
    )

    # Sample precision matrix from Wishart prior
    prec_par[k, , ] <- rWishart(
      n = 1,
      df = prepped_priors$wishdf[k],
      Sigma = solve(prepped_priors$omega[k, , ])
    )[, , 1]

    # Sample measurement error precision
    prec_logy[k] <- rgamma(
      n = 1,
      shape = prepped_priors$prec.logy.hyp[k, 1],
      rate = prepped_priors$prec.logy.hyp[k, 2]
    )
  }

  # Initialize arrays for subject-level parameters
  par <- array(NA, dim = c(nsubj, n_antigen_isos, n_params))
  y0 <- array(NA, dim = c(nsubj, n_antigen_isos))
  y1 <- array(NA, dim = c(nsubj, n_antigen_isos))
  t1 <- array(NA, dim = c(nsubj, n_antigen_isos))
  alpha <- array(NA, dim = c(nsubj, n_antigen_isos))
  shape <- array(NA, dim = c(nsubj, n_antigen_isos))

  # Sample subject-level parameters for each subject and biomarker
  for (subj in seq_len(nsubj)) {
    for (k in seq_len(n_antigen_isos)) {
      # Sample individual parameters from population distribution
      par[subj, k, ] <- MASS::mvrnorm(
        n = 1,
        mu = mu_par[k, ],
        Sigma = solve(prec_par[k, , ])
      )

      # Transform to natural scale (matching JAGS model)
      y0[subj, k] <- exp(par[subj, k, 1])
      y1[subj, k] <- y0[subj, k] + exp(par[subj, k, 2]) # par[,,2] is log(y1-y0)
      t1[subj, k] <- exp(par[subj, k, 3])
      alpha[subj, k] <- exp(par[subj, k, 4])
      shape[subj, k] <- exp(par[subj, k, 5]) + 1 # par[,,5] is log(shape-1)
    }
  }

  # Generate simulated antibody observations
  logy_sim <- prepped_data$logy
  smpl_t <- prepped_data$smpl.t
  nsmpl <- prepped_data$nsmpl

  for (subj in seq_len(nsubj)) {
    for (obs in seq_len(nsmpl[subj])) {
      for (k in seq_len(n_antigen_isos)) {
        # Calculate mean antibody level at this timepoint
        t_obs <- smpl_t[subj, obs]

        # Skip if no timepoint
        if (is.na(t_obs)) {
          next
        }

        # Calculate mu.logy using the antibody dynamics model
        # This matches the JAGS model logic
        beta <- log(y1[subj, k] / y0[subj, k]) / t1[subj, k]

        if (t_obs <= t1[subj, k]) {
          # Active infection period (before peak)
          mu_logy <- log(y0[subj, k]) + beta * t_obs
        } else {
          # Recovery period (after peak)
          # Calculate the argument inside the log
          log_arg <- y1[subj, k]^(1 - shape[subj, k]) -
            (1 - shape[subj, k]) * alpha[subj, k] * (t_obs - t1[subj, k])

          # Check if log_arg is positive and finite
          if (is.finite(log_arg) && log_arg > 0) {
            mu_logy <- (1 / (1 - shape[subj, k])) * log(log_arg)
          } else {
            # Set to NA if invalid
            mu_logy <- NA
          }
        }

        # Add measurement noise (only if mu_logy is finite)
        if (is.finite(mu_logy)) {
          sd_logy <- 1 / sqrt(prec_logy[k])
          logy_sim[subj, obs, k] <- rnorm(
            n = 1,
            mean = mu_logy,
            sd = sd_logy
          )
        } else {
          # Leave as NA if mu_logy is not finite
          logy_sim[subj, obs, k] <- NA
        }
      }
    }
  }

  # Create output with same structure as input
  to_return <- prepped_data
  to_return$logy <- logy_sim

  # Add attributes to track that this is simulated data
  to_return <- structure(
    to_return,
    simulated_from_priors = TRUE,
    sim_params = list(
      mu_par = mu_par,
      prec_par = prec_par,
      prec_logy = prec_logy,
      y0 = y0,
      y1 = y1,
      t1 = t1,
      alpha = alpha,
      shape = shape
    )
  )

  return(to_return)
}
