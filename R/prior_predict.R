#' @title Create Prior Predictive Plot
#' @description
#' Creates prior predictive plots for a specified prior distribution before 
#' fitting the model to observed data.
#' The function generates draws from the hierarchical prior distribution and
#' propagates these draws through the model to obtain distributions of the
#' predictive-level parameters. The resulting plots can be used to assess
#' whether the specified priors imply biologically or scientifically plausible
#' parameter values and model trajectories.
#' 
#' Prior draws are generated hierarchically. At the highest level,
#' hyperparameters define the distribution of the latent model parameters on 
#' the log scale. Specifically, `mu_hyp_param` describes the prior distribution 
#' governing the location `log(mean)` of each latent parameter, while 
#' `prec_hyp_param` describes the prior distribution governing its precision. 
#' Draws from these distributions determine the corresponding parameter-level 
#' distribution, from which the latent parameter vector \eqn{\mathrm{par}} is 
#' sampled.
#'
#' The hierarchy can be summarized as:
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
#' The exponential transformations ensure that \eqn{y_0}, \eqn{t_1}, and
#' \eqn{\alpha} are positive. Defining \eqn{y_1} relative to \eqn{y_0}
#' ensures that \eqn{y_1 > y_0}, while the transformation of \eqn{r}
#' ensures that \eqn{r > 1}. 
#'
#' Depending on the requested output, `prior_predict()` displays either the
#' distributions of these prior predictive parameter draws as density plots
#' or the model trajectories implied by the draws. Density plots show the
#' range of transformed parameter values supported by the prior specification. 
#' Trajectory plots show how uncertainty in the prior distributions 
#' affect the model's predicted seroresponse.
#'
#' @param mu_hyp_param A [numeric] [vector] of 5 values representing the prior
#' mean on the log scale for the population level parameters 
#' (y0, y1, t1, alpha, r) for each  biomarker. Will be 5 values long 
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
  log_y = FALSE) {
  
  type <- match.arg(type)
  n_params <- 5L
  ## ---------------------------------------------------------
  ## Validate inputs
  ## ---------------------------------------------------------
  priors <- validate_prior_predict_inputs(mu_hyp_param = mu_hyp_param,
                                          prec_hyp_param = prec_hyp_param,
                                          omega_param = omega_param,
                                          wishdf_param = wishdf_param,
                                          prec_logy_hyp_param = 
                                            prec_logy_hyp_param,
                                          n = n,
                                          n_params = n_params)
  
  ## ---------------------------------------------------------
  ## Draw from hierarchical priors
  ## ---------------------------------------------------------
  # Turning precision matrix into covariance matrix
  mu_cov <- diag(1 / prec_hyp_param)
  
  # Inverting omega precision matrix to covariance matrix
  wishart_scale <- solve(diag(omega_param))
  # Creating empty matrix to store subject level parameter draws
  par_draws <- matrix(NA_real_, nrow = n, ncol = n_params)
  colnames(par_draws) <- paste0("par", seq_len(n_params))
  
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
    # Saving the draws
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
    
    plot <- ggplot2::ggplot(density_data,
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
    curve_data <- lapply(seq_len(n),
      function(i) {
        tt <- time
        
        antibody <- ab(
          t = tt,
          y0 = y0[i],
          y1 = y1[i],
          t1 = t1[i],
          alpha = alpha[i],
          shape = shape[i],
          decay_type = "power"
        )
        data.frame(draw = i, time = tt, antibody = antibody)
      }
    )
    curve_data <- do.call(rbind, curve_data)
    # Checking to see if non-finite values were created
    finite <- is.finite(curve_data$antibody)
    
    if (any(!finite)) {
      cli::cli_warn("{sum(!finite)} prior-predictive values were non-finite and 
      were omitted from the plot.")
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
