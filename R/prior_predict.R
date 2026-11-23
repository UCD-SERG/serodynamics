#' @title Create Prior Predictive Plot
#' @description
#' Creates prior predictive plots for a specified prior distribution before 
#' fitting a power-law decay model to observed data. 
#' The function generates draws from the hierarchical prior distribution and
#' propagates these draws through the model to obtain distributions of the
#' predictive-level parameters. The resulting plots can be used to assess
#' whether the specified priors imply biologically or scientifically plausible
#' parameter values and model trajectories.
#' 
#' Prior draws are generated hierarchically. At the highest level,
#' hyperparameters define the distribution of the latent model parameters on 
#' the log scale. Specifically, `mu_hyp` describes the prior distribution 
#' governing the location `log(mean)` of each latent parameter, while 
#' `prec_hyp` describes the prior distribution governing its precision. 
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
#' mean for the population level parameters
#' parameters (y0, y1, t1, alpha, r) for each biomarker. Will be 5 values long 
#' specified by the user, representing the following parameters:
#'    - y0 = baseline antibody concentration
#'    - y1 = peak antibody concentration
#'    - t1 = time to peak
#'    - alpha = decay rate 
#'    - r = shape parameter (If running `decay_type == "exponential"` no shape
#'    parameter needs to be specified).
#' @param prec_hyp_param A [numeric] [vector] of 5 values corresponding to
#' hyperprior diagonal entries for the precision matrix (i.e. inverse variance)
#' representing prior covariance of uncertainty around `mu_hyp_param`.
#' Will be 5 values long corresponding to the 5 estimated parameters 
#' @param omega_param A [numeric] [vector] of 5 values corresponding to the
#' diagonal entries representing the Wishart hyperprior
#' distributions of `prec_hyp_param`, describing how much we expect parameters
#' to vary between individuals.
#' Will be 5 values long corresponding to the 5 estimated parameters 
#' @inheritParams prep_priors wishdf_param prec_logy_hyp_param
#' @param noise Logical. If `TRUE`, simulate observations by
#'   adding independent Normal observation error on the log
#'   antibody scale. If `FALSE` (default), plot the latent
#'   antibody trajectories without observation error.
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
#' @param log_x Logical. If `TRUE`, parameter densities are
#'   displayed on a log10 x-axis. Only applies when `type = "density"`.
#'   Default is `FALSE`.
#' @return An object of class `"serodynamics_prior_predict"` containing the
#'   plot and simulated prior draws. The object prints as a ggplot.
#'   Quantiles (2.5%, median, and 97.5%) for each biological model parameter
#'   are stored in the `"prior_summary"` attribute and can be retrieved with
#'   `summary()`.
#'
#' @export
#' @example inst/examples/examples-prior_predict.R
prior_predict <- function(
  ...,
  n = 1000,
  type = c("curves", "density"),
  time = seq(0, 200, length.out = 200),
  log_y = FALSE,
  log_x = FALSE,
  noise = FALSE) {
  
  type <- match.arg(type)
  
  n_params <- 5L
  ## ---------------------------------------------------------
  ## Validate inputs
  ## ---------------------------------------------------------
  # Use the same prior preparation as model fitting.
  pr <- prep_priors(max_antigens = 1, decay_type = "power", ...)
  mu_hyp <- pr$mu.hyp[1, ]
  prec_hyp <- pr$prec.hyp[1, , ]
  omega <- pr$omega[1, , ]
  wishdf <- pr$wishdf
  prec_logy_hyp <- pr$prec.logy.hyp[1, ]
  validate_prior_predict_inputs(mu_hyp = mu_hyp, prec_hyp = prec_hyp,
                                omega = omega, prec_logy_hyp = prec_logy_hyp,
                                wishdf = wishdf, n = n, n_params = n_params,
                                noise = noise, time = time)
  
  ## ---------------------------------------------------------
  ## Draw from hierarchical priors
  ## ---------------------------------------------------------
  draws <- draw_prior_predictive(pr = pr, n = n)
  
  ## ---------------------------------------------------------
  ## Parameter summaries
  ## ---------------------------------------------------------
  model_parameters <- c("y0", "y1", "t1", "alpha", "shape")
  prior_summary <- do.call(rbind,
                           lapply(model_parameters, function(param) {
                             qs <- stats::quantile(draws[[param]], 
                                                   probs = c(0.025, 0.5, 0.975),
                                                   na.rm = TRUE, names = FALSE)
                             data.frame(parameter = param, q2.5 = qs[1], 
                                        median = qs[2], 
                                        q97.5 = qs[3], row.names = NULL)
                           }))
  ## ---------------------------------------------------------
  ## Plot parameter densities
  ## ---------------------------------------------------------
  if (type == "density") {
    density_data <- data.frame(parameter = rep(model_parameters, each = n),
                               value = unlist(draws[model_parameters], 
                                              use.names = FALSE))
    plot <- ggplot2::ggplot(density_data,
                            ggplot2::aes(x = .data$value)) +
      ggplot2::geom_density() +
      ggplot2::facet_wrap(~parameter, scales = "free") +
      ggplot2::labs(x = NULL, y = "Density", 
                    title = "Prior parameter distributions") +
      ggplot2::theme_bw()
    if (log_x) {
      plot <- plot +
        ggplot2::scale_x_log10()
    }
    plot_data <- density_data
  }
  
  # ---------------------------------------------------------
  # Prior predictive antibody curves
  # ---------------------------------------------------------
  if (type == "curves") {
    curve_data <- lapply(seq_len(n), function(i) {
      tt <- time
      # Generate biological trajectory
      antibody <- ab(t = tt, y0 = draws$y0[i], y1 = draws$y1[i], 
                     t1 = draws$t1[i], alpha = draws$alpha[i], 
                     shape = draws$shape[i], decay_type = "power")
      # Simulated observations on the log scale
      if (noise) {
        if (any(!is.finite(antibody)) || any(antibody <= 0)) {
          cli::cli_abort("Observation noise requires positive, finite
            antibody trajectories.")
        }
        antibody <- exp(log(antibody) + 
                          stats::rnorm(length(tt), mean = 0, 
                                       sd = draws$sigma_logy[i]))
      }
      data.frame(draw = i, time = tt, antibody = antibody)
    })
    curve_data <- do.call(rbind, curve_data)
    finite <- is.finite(curve_data$antibody)
    if (any(!finite)) {
      cli::cli_warn(
        "{sum(!finite)} prior-predictive values were
        non-finite and were omitted from the plot."
      )
      curve_data <- curve_data[finite, , drop = FALSE]
    }
    
    plot <- ggplot2::ggplot(curve_data, 
                            ggplot2::aes(x = .data$time, y = .data$antibody, 
                                         group = .data$draw)) +
      ggplot2::geom_line(alpha = 0.08) +
      ggplot2::labs(x = "Time", y = "Antibody level", title = if (noise) {
        "Prior predictive observations"
      } else {
        "Prior biological trajectories"
      }
      ) +
      ggplot2::theme_bw()
    if (log_y) {
      plot <- plot + ggplot2::scale_y_log10()
    }
    plot_data <- curve_data
  }
  
  # ---------------------------------------------------------
  # Construct S3 object
  # ---------------------------------------------------------
  out <- list(plot = plot, draws = draws, plot_data = plot_data, 
              type = type, priors = pr)
  class(out) <- "serodynamics_prior_predict"
  attr(out, "prior_summary") <- prior_summary
  out
}
