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
#' @inheritDotParams prep_priors
#' @param noise Logical. If `TRUE`, simulate observations by
#'   adding independent Normal observation error on the log
#'   antibody scale. If `FALSE` (default), plot the latent
#'   antibody trajectories without observation error.
#' @param decay_type Character. Antibody decay model used
#'   to generate trajectories. Defaults to `"power"`.
#'   Supported values must match the antibody kinetics
#'   function used internally.
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
  ...,
  n = 1000,
  type = c("curves", "density"),
  time = seq(0, 200, length.out = 200),
  log_y = FALSE,
  log_x = FALSE,
  noise = FALSE,
  decay_type = "power") {
  
  type <- match.arg(type)
  n_params <- 5L
  ## ---------------------------------------------------------
  ## Validate inputs
  ## ---------------------------------------------------------

  # Use the same prior preparation as model fitting.
  pr <- prep_priors(
    max_antigens = 1,
    ...
  )
  
  mu_hyp <- pr$mu.hyp[1, ]
  prec_hyp <- pr$prec.hyp[1, , ]
  omega <- pr$omega[1, , ]
  wishdf <- pr$wishdf
  prec_logy_hyp <- pr$prec.logy.hyp[1, ]
  
  validate_prior_predict_inputs(mu_hyp = mu_hyp,
                                prec_hyp = prec_hyp,
                                omega = omega,
                                prec_logy_hyp = prec_logy_hyp,
                                wishdf = wishdf,
                                n = n,
                                n_params = n_params,
                                noise = noise,
                                time = time)
  
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
      qs <- stats::quantile(
        draws[[param]],
        probs = c(0.025, 0.5, 0.975),
        na.rm = TRUE,
        names = FALSE)
      
      data.frame(parameter = param, q2.5 = qs[1], median = qs[2], 
                 q97.5 = qs[3], row.names = NULL)
    })
  )
  
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
      
      # Noise-free biological trajectory
      antibody <- ab(
        t = tt,
        y0 = y0[i],
        y1 = y1[i],
        t1 = t1[i],
        alpha = alpha[i],
        shape = shape[i],
        decay_type = decay_type
      )
      
      # Simulated observations on the log scale
      if (noise) {
        
        if (any(!is.finite(antibody)) ||
              any(antibody <= 0)) {
          cli::cli_abort(
            "Observation noise requires positive, finite
            antibody trajectories."
          )
        }
        
        antibody <- exp(log(antibody) +
                          stats::rnorm(length(tt), mean = 0, 
                                       sd = sigma_logy[i]))
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
      
      curve_data <- curve_data[
        finite, ,
        drop = FALSE
      ]
    }
    
    plot <- ggplot2::ggplot(curve_data,
                            ggplot2::aes(x = .data$time, y = .data$antibody, 
                                         group = .data$draw)) +
      ggplot2::geom_line(alpha = 0.08) +
      ggplot2::labs(
        x = "Time",
        y = "Antibody level",
        title = if (noise) {
          "Prior predictive observations"
        } else {
          "Prior biological trajectories"
        }
      ) +
      ggplot2::theme_bw()
    if (log_y) {
      plot <- plot +
        ggplot2::scale_y_log10()
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
