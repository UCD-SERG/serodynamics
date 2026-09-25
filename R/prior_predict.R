#' @title Create Prior Predictive Plot
#' @description
#' Creates a prior predictive plot. The prior predictive plot can represent 
#' either the population or predictive level parameters. Output figures consist 
#' of either a density plot of the parameters or the varying plotted 
#' trajectories.
#' Prior draws are generated through the hierarchical model:
#'
#' \deqn{
#' \mu_{\mathrm{par}} \rightarrow
#' \mathrm{prec}_{\mathrm{par}} \rightarrow
#' \mathrm{par} \rightarrow
#' (y_0, y_1, t_1, \alpha, r)
#' }
#'
#' where the transformed parameters are
#'
#' \deqn{
#' y_0 = \exp(\mathrm{par}_1)
#' }
#'
#' \deqn{
#' y_1 = y_0 + \exp(\mathrm{par}_2)
#' }
#'
#' \deqn{
#' t_1 = \exp(\mathrm{par}_3)
#' }
#'
#' \deqn{
#' \alpha = \exp(\mathrm{par}_4)
#' }
#'
#' \deqn{
#' r = 1 + \exp(\mathrm{par}_5).
#' }
#'
#' @param mu_hyp_param A [numeric] [vector] of 5 values representing the prior
#' mean for the population level parameters
#' parameters (y0, y1, t1, alpha, r) for each biomarker. Will be 5 values long 
#' specified by the user, representing the following parameters:
#'    - y0 = baseline antibody concentration
#'    - y1 = peak antibody concentration
#'    - t1 = time to peak
#'    - alpha = decay rate 
#'    - r = shape parameter
#' @param prec_hyp_param A [numeric] [vector] of 5 values corresponding to
#' hyperprior diagonal entries for the precision matrix (i.e. inverse variance)
#' representing prior covariance of uncertainty around `mu_hyp_param`.
#' @param omega_param A [numeric] [vector] of 5 values corresponding to the
#' diagonal entries representing the Wishart hyperprior
#' distributions of `prec_hyp_param`, describing how much we expect parameters
#' to vary between individuals.
#' @inheritParams prep_priors wishdf_param prec_logy_hyp_param
#' @param n Number of prior draws. Default is 1000.
#' @param type Character string specifying the output visualization.
#'   `"curves"` plots prior-predictive antibody trajectories and `"density"`
#'   plots marginal parameter densities.
#' @param time Numeric vector giving times at which prior-predictive antibody
#'   trajectories should be evaluated. Defaults to 200 equally spaced points
#'   between 0 and 200.
#' @param log_y Logical. If `TRUE`, prior predictive antibody curves are
#'   displayed on a log10 y-axis. Only applies when `type = "curves"`.
#'   Default is `FALSE`.
#' @param seed Optional integer seed for reproducible prior simulation.
#' @return An object of class `"serodynamics_prior_predict"` containing the
#'   plot and simulated prior draws. The object prints as a ggplot.
#'   Quantiles (2.5%, median, and 97.5%) for each biological model parameter
#'   are stored in the `"prior_summary"` attribute and can be retrieved with
#'   `summary()`.
#'
#' @export
#' 
#' @examples
#' \dontrun{
#' pp <- prior_predict(
#'   mu_hyp_param = c(0.5, 5, 2, -2, -3),
#'   prec_hyp_param = rep(1, 5),
#'   omega_param = c(1, 5, 1, 5, 1),
#'   wishdf_param = 20,
#'   prec_logy_hyp_param = c(4, 1),
#'   n = 500,
#'   type = "curves"
#' )
#'
#' pp
#' summary(pp)
#'
#' prior_predict(
#'   mu_hyp_param = c(0.5, 5, 2, -2, -3),
#'   prec_hyp_param = rep(1, 5),
#'   omega_param = c(1, 5, 1, 5, 1),
#'   wishdf_param = 20,
#'   prec_logy_hyp_param = c(4, 1),
#'   n = 1000,
#'   type = "density"
#' )
#' }

prior_predict <- function(
  mu_hyp_param = NULL,
  prec_hyp_param = NULL,
  omega_param = NULL,
  wishdf_param = NULL,
  prec_logy_hyp_param = NULL,
  n = 1000,
  type = c("curves", "density"),
  time = seq(0, 200, length.out = 200),
  log_y = FALSE,
  seed = NULL) {
  
  type <- match.arg(type)
  
  n_params <- 5L
  
  ## ---------------------------------------------------------
  ## Validate inputs
  ## ---------------------------------------------------------
  
  priors <- list(
    mu_hyp_param = mu_hyp_param,
    prec_hyp_param = prec_hyp_param,
    omega_param = omega_param,
    wishdf_param = wishdf_param,
    prec_logy_hyp_param = prec_logy_hyp_param
  )
  
  missing_priors <- names(priors)[vapply(priors, is.null, logical(1))]
  
  if (length(missing_priors) > 0) {
    cli::cli_abort(c(
      "x" = "All prior arguments must be supplied.",
      "i" = "Missing: {paste(missing_priors, collapse = ', ')}"
    ))
  }
  
  if (length(mu_hyp_param) != n_params) {
    cli::cli_abort(
      "{.arg mu_hyp_param} must have length {n_params}."
    )
  }
  
  if (length(prec_hyp_param) != n_params) {
    cli::cli_abort(
      "{.arg prec_hyp_param} must have length {n_params}."
    )
  }
  
  if (any(prec_hyp_param <= 0)) {
    cli::cli_abort(
      "All values of {.arg prec_hyp_param} must be greater than zero."
    )
  }
  
  if (length(wishdf_param) != 1 || wishdf_param < n_params) {
    cli::cli_abort(
      "{.arg wishdf_param} must be at least {n_params}."
    )
  }
  
  if (length(prec_logy_hyp_param) != 2 ||
        any(prec_logy_hyp_param <= 0)) {
    cli::cli_abort(
      "{.arg prec_logy_hyp_param} must contain two positive values."
    )
  }
  
  if (!is.numeric(n) || length(n) != 1 || n < 1) {
    cli::cli_abort(
      "{.arg n} must be a positive integer."
    )
  }
  n <- as.integer(n)
  if (!is.null(seed)) {
    set.seed(seed)
  }
  
  ## omega_param may be supplied in the same compact form used by
  ## run_serodynamics(), or as a full matrix.
  if (is.vector(omega_param) && length(omega_param) == n_params) {
    omega <- diag(omega_param)
  } else if (
    is.matrix(omega_param) &&
      all(dim(omega_param) == c(n_params, n_params))
  ) {
    omega <- omega_param
  } else {
    cli::cli_abort(
                   "{.arg omega_param} must be a length-{n_params} vector or a
                    {n_params} x {n_params} matrix.")
  }
  
  ## Ensure omega is positive definite
  tryCatch(chol(omega), error = function(e) {
    cli::cli_abort(
                   "{.arg omega_param} must define a positive-definite 
                    matrix.")
  })
  
  ## ---------------------------------------------------------
  ## Draw from hierarchical priors
  ## ---------------------------------------------------------
  # Turning precision matrix into covariance matrix
  mu_cov <- diag(1 / prec_hyp_param)
  
  # Inverting omega precision matrix to covariance matrix
  wishart_scale <- solve(omega)
  # Creating empty matrix to store subject level parameter draws
  par_draws <- matrix(NA_real_, nrow = n, ncol = n_params)
  colnames(par_draws) <- paste0("par", seq_len(n_params))
  # Empty matrix for population-level parameter draws
  mu_draws <- matrix(NA_real_, nrow = n, ncol = n_params)
  
  # Repeat the hierarchical prior simulation n times
  for (i in seq_len(n)) {
    # Drawing population level means using multivariate normal. Represents
    # one possible set of population means. Still on log scale.
    mu_i <- MASS::mvrnorm(n = 1, mu = mu_hyp_param, Sigma = mu_cov)
    # Samples 5x5 precision matrix. Variability among individuals and c
    # correlation among parameters. 
    prec_i <- stats::rWishart(n = 1, df = wishdf_param, Sigma = wishart_scale
    )[, , 1]
    # Draws an individual. Integrates population variability and between 
    # subject variability.
    par_i <- MASS::mvrnorm(n = 1, mu = mu_i, Sigma = solve(prec_i))
    # Saving the two draws
    mu_draws[i, ] <- mu_i
    par_draws[i, ] <- par_i
  }
  
  ## Observation precision
  prec_logy <- stats::rgamma(n, shape = prec_logy_hyp_param[1],
                             rate = prec_logy_hyp_param[2])
  # Converting precision to sd
  sigma_logy <- sqrt(1 / prec_logy)
  
  ## ---------------------------------------------------------
  ## Transform to biological parameters
  ## ---------------------------------------------------------
  # Turning everything into the natural scale
  y0 <- exp(par_draws[, 1])
  change_y <- exp(par_draws[, 2])
  y1 <- y0 + change_y
  t1 <- exp(par_draws[, 3])
  alpha <- exp(par_draws[, 4])
  shape <- exp(par_draws[, 5]) + 1
  beta <- log(y1 / y0) / t1
  draws <- data.frame(draw = seq_len(n), y0 = y0, y1 = y1, t1 = t1, 
                      alpha = alpha, shape = shape, beta = beta,
                      sigma_logy = sigma_logy)
  
  ## ---------------------------------------------------------
  ## Parameter summaries
  ## ---------------------------------------------------------
  
  model_parameters <- c("y0", "y1", "t1", "alpha", "shape")
  # Summarizing parameter summaries
  prior_summary <- do.call(
    rbind,
    lapply(model_parameters, function(x) {
      qs <- stats::quantile(draws[[x]], probs = c(0.025, 0.5, 0.975),
                            na.rm = TRUE, names = FALSE)
      data.frame(parameter = x, q2.5 = qs[1], median = qs[2], q97.5 = qs[3],
                 row.names = NULL)
    })
  )
  
  ## ---------------------------------------------------------
  ## Plot parameter densities
  ## ---------------------------------------------------------
  
  if (type == "density") {
    
    density_data <- data.frame(
                               parameter = rep(model_parameters, each = n),
                               value = unlist(draws[model_parameters], 
                                              use.names = FALSE))
    
    plot <- ggplot2::ggplot(
                            density_data,
                            ggplot2::aes(x = .data$value)) +
      ggplot2::geom_density() +
      ggplot2::facet_wrap(~parameter, scales = "free") +
      ggplot2::labs(x = NULL, y = "Density", 
                    title = "Prior parameter distributions") +
      ggplot2::theme_bw()
    
    plot_data <- density_data
  }
  
  ## ---------------------------------------------------------
  ## Plot prior predictive antibody curves
  ## ---------------------------------------------------------
  
  if (type == "curves") {
    curve_data <- lapply(
      seq_len(n),
      function(i) {
        tt <- time
        log_y <- numeric(length(tt))
        active <- tt <= t1[i]
        
        ## Active infection phase
        log_y[active] <- log(y0[i]) + beta[i] * tt[active]
        
        ## Recovery phase
        # Checking to see if there is a decay phase
        if (any(!active)) {
          
          q <- shape[i] - 1
          
          # Calculating recovery time
          recovery_time <-
            tt[!active] - t1[i]
          
          # Non-linear recovery equation
          log_y[!active] <- -1 / q * log(y1[i]^(-q) + q * alpha[i] * 
                                           recovery_time)
        }
        
        data.frame(draw = i, time = tt, antibody = exp(log_y))
      }
    )
    curve_data <- do.call(rbind, curve_data)
    # Checking to see if non-finite values were created
    finite <- is.finite(curve_data$antibody)
    
    if (any(!finite)) {
      cli::cli_warn(
        "{sum(!finite)} prior-predictive values were non-finite and were 
        omitted from the plot."
      )
      curve_data <- curve_data[finite, , drop = FALSE]
    }
    
    plot <- ggplot2::ggplot(curve_data,
                            ggplot2::aes(x = .data$time, y = .data$antibody, 
                                         group = .data$draw)) +
      ggplot2::geom_line(alpha = 0.08) +
      ggplot2::labs(x = "Time", y = "Antibody level",
                    title = "Prior predictive antibody trajectories") +
      ggplot2::theme_bw()
    if (log_y) {
      plot <- plot +
        ggplot2::scale_y_log10()
    }
    plot_data <- curve_data
  }
  
  ## ---------------------------------------------------------
  ## Construct S3 object
  ## ---------------------------------------------------------
  out <- list(plot = plot, draws = draws, plot_data = plot_data,
              type = type, priors = priors)
  class(out) <- "serodynamics_prior_predict"
  attr(out, "prior_summary") <- prior_summary
  out
}
