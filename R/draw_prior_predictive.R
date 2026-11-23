#' Simulate Individual-Level Prior Predictive Parameters
#'
#' @param pr Prepared priors returned by prep_priors().
#' @param n Number of prior draws.
#'
#' @return Data frame of individual-level biological parameters.
#' @keywords internal
draw_prior_predictive <- function(pr, n = 10000) {
  
  stopifnot(length(n) == 1, is.finite(n),
            n >= 1, n == as.integer(n))
  
  n_params <- 5L
  
  # Extract prepared prior parameters
  mu_hyp <- as.numeric(pr$mu.hyp[1, ])
  prec_hyp <- pr$prec.hyp[1, , ]
  omega <- pr$omega[1, , ]
  wishdf <- as.numeric(pr$wishdf)
  prec_logy_hyp <- as.numeric(pr$prec.logy.hyp[1, ])
  
  # Validate dimensions
  stopifnot(
    length(mu_hyp) == n_params,
    identical(dim(prec_hyp), c(5L, 5L)),
    identical(dim(omega), c(5L, 5L)),
    length(wishdf) == 1,
    wishdf > n_params - 1,
    length(prec_logy_hyp) == 2,
    all(prec_logy_hyp > 0)
  )
  
  # Precision to covariance
  mu_cov <- solve(prec_hyp)
  wishart_scale <- solve(omega)
  
  # Allocate parameter draws
  par_draws <- matrix(
    NA_real_,
    nrow = n,
    ncol = n_params
  )
  
  # Draw from full hierarchical prior
  for (i in seq_len(n)) {
    
    # Population location parameters
    mu_i <- MASS::mvrnorm(
      n = 1,
      mu = mu_hyp,
      Sigma = mu_cov
    )
    
    # Between-individual precision matrix
    prec_i <- stats::rWishart(
      n = 1,
      df = wishdf,
      Sigma = wishart_scale
    )[, , 1]
    
    # Individual latent parameters
    par_draws[i, ] <- MASS::mvrnorm(
      n = 1,
      mu = mu_i,
      Sigma = solve(prec_i)
    )
  }
  
  # Observation-level uncertainty
  prec_logy <- stats::rgamma(
    n,
    shape = prec_logy_hyp[1],
    rate = prec_logy_hyp[2]
  )
  
  sigma_logy <- sqrt(1 / prec_logy)
  
  # Transform to biological parameters
  y0 <- exp(par_draws[, 1])
  change_y <- exp(par_draws[, 2])
  y1 <- y0 + change_y
  t1 <- exp(par_draws[, 3])
  alpha <- exp(par_draws[, 4])
  shape <- 1 + exp(par_draws[, 5])
  
  # Stable computation of beta
  beta <- (
    log1p(change_y / y0)
  ) / t1
  
  data.frame(
    draw = seq_len(n),
    y0 = y0,
    y1 = y1,
    t1 = t1,
    alpha = alpha,
    shape = shape,
    beta = beta,
    sigma_logy = sigma_logy
  )
}
