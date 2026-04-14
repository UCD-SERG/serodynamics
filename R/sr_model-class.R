#' `sr_model` class
#'
#' @description
#' An S3 class representing the output of a Bayesian MCMC model
#' fitted by [run_mod()]. The `sr_model` object is a subclass
#' of [tibble::tbl_df] containing MCMC samples from the joint posterior
#' distribution of host-specific antibody kinetic parameters,
#' conditional on the provided input data.
#'
#' Each row represents one posterior draw for one parameter, one
#' antigen-isotype combination, one subject, and one stratification level.
#'
#' @section Data columns:
#'
#' \describe{
#'   \item{Iteration}{[integer] MCMC sampling iteration index.}
#'   \item{Chain}{[integer] MCMC chain index (between 1 and the number of
#'   chains specified in [run_mod()]).}
#'   \item{Parameter}{[character] name of the antibody dynamic curve parameter.
#'   One of:
#'   \itemize{
#'     \item `y0` -- baseline antibody concentration
#'     \item `y1` -- peak antibody concentration
#'     \item `t1` -- time to peak
#'     \item `shape` -- shape parameter
#'     \item `alpha` -- decay rate
#'   }}
#'   \item{Iso_type}{[character] antibody/antigen isotype combination being
#'   evaluated (e.g., `"HlyE_IgA"`, `"HlyE_IgG"`).}
#'   \item{Stratification}{[character] the level of the stratification variable
#'   used when fitting the model, or `"None"` if no stratification was
#'   specified.}
#'   \item{Subject}{[character] identifier of the subject. Includes observed
#'   subjects as well as `"newperson"`, which represents the posterior
#'   predictive distribution for a hypothetical new individual with no observed
#'   data.}
#'   \item{value}{[numeric] posterior sample value of the parameter.}
#' }
#'
#' @section Attributes:
#'
#' In addition to the standard [tibble::tbl_df] attributes (`names`,
#' `row.names`, `class`), an `sr_model` object carries the following
#' custom attributes:
#'
#' \describe{
#'   \item{nChains}{[integer] number of MCMC chains run.}
#'   \item{nParameters}{[integer] number of parameters estimated in the model.}
#'   \item{nIterations}{[integer] total number of MCMC iterations specified.}
#'   \item{nBurnin}{[integer] number of burn-in iterations discarded before
#'   sampling.}
#'   \item{nThin}{[integer] thinning interval (ratio of total iterations to
#'   retained samples, i.e., `niter / nmc`).}
#'   \item{population_params}{(optional) a [tibble::tbl_df] of modeled
#'   population-level parameters, included when `with_pop_params = TRUE` in
#'   [run_mod()]. Indexed by `Iteration`, `Chain`, `Parameter`, `Iso_type`,
#'   and `Stratification`. Contains the following population parameters:
#'   \itemize{
#'     \item `mu.par` -- the population means of the host-specific model
#'     parameters (on logarithmic scales).
#'     \item `prec.par` -- the population precision matrix of the
#'     hyperparameters (with diagonal elements equal to inverse variances).
#'     \item `prec.logy` -- a vector of population precisions (inverse
#'     variances), one per antigen/isotype combination.
#'   }}
#'   \item{priors}{a [list] summarizing the input priors used in the model,
#'   with the following elements:
#'   \itemize{
#'     \item `mu_hyp_param` -- prior means for y0, y1, t1, shape, and alpha.
#'     \item `prec_hyp_param` -- precision hyperparameters (inverse variances).
#'     \item `omega_param` -- Wishart hyperprior diagonal entries.
#'     \item `wishdf` -- degrees of freedom for the Wishart distribution.
#'     \item `prec_logy_hyp_param` -- log-scale precision hyperparameters.
#'   }}
#'   \item{fitted_residuals}{a [data.frame] containing fitted values and
#'   residuals for all observations, with columns:
#'   \itemize{
#'     \item `Subject` -- subject identifier.
#'     \item `Iso_type` -- antigen-isotype combination.
#'     \item `t` -- time since infection.
#'     \item `fitted` -- fitted value calculated from posterior parameter
#'     estimates.
#'     \item `residual` -- residual (observed minus fitted).
#'   }}
#'   \item{jags.post}{(optional) a [list] of raw [runjags::run.jags()] output
#'   objects, one per stratification level. Included when
#'   `with_post = TRUE` in [run_mod()]. These objects can be large.}
#' }
#'
#' @section Construction:
#'
#' `sr_model` objects are created by [run_mod()] and should not normally
#' be constructed directly.
#'
#' @section Inheritance:
#'
#' The class hierarchy is
#' `sr_model` > `tbl_df` > `tbl` > `data.frame`,
#' so standard [dplyr] and [tibble] operations work on `sr_model` objects.
#'
#' @seealso
#' * [run_mod()] -- the constructor function.
#' * [post_summ()] -- posterior summary table.
#' * [plot_predicted_curve()] -- predicted antibody response curves.
#' * [plot_jags_trace()] -- MCMC trace plots.
#' * [plot_jags_dens()] -- posterior density plots.
#' * [plot_jags_Rhat()] -- Rhat diagnostic plots.
#' * [plot_jags_effect()] -- effect size plots.
#'
#' @name sr_model-class
#' @aliases sr_model
NULL
