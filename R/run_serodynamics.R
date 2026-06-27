#' @title Run Jags Model
#' @author Sam Schildhauer
#' @description
#'  `run_serodynamics()` takes a data frame and adjustable MCMC inputs to
#'  [runjags::run.jags()] as an MCMC
#'  Bayesian model to estimate antibody dynamic curve parameters.
#'  The [rjags::jags.model()] models seroresponse dynamics to an
#'  infection. The antibody dynamic curve includes the following parameters:
#'  - y0 = baseline antibody concentration
#'  - y1 = peak antibody concentration
#'  - t1 = time to peak
#'  - shape = shape parameter
#'  - alpha = decay rate
#' @param data A [base::data.frame()] with the following columns.
#' @param file_mod The name of the file that contains model structure.
#' @param nchain An [integer] between 1 and 4 that specifies
#' the number of MCMC chains to be run per jags model.
#' @param nadapt An [integer] specifying the number of adaptations per chain.
#' @param nburn An [integer] specifying the number of burn ins before sampling.
#' @param nmc An [integer] specifying the number of samples in posterior chains.
#' @param niter An [integer] specifying the number of iterations.
#' @param strat A [character] string specifying the stratification variable,
#' entered in quotes.
#' @param decay_type A [character] string specifying the type of antibody
#'   decay function to use. Either `"power"` (default) for power function
#'   decay (Teunis et al. 2016) or `"exponential"` for exponential decay.
#' @param with_post A [logical] value specifying whether a raw `jags.post`
#' object should be included as an optional `"jags.post"` attribute on the
#' returned `sr_model` tibble
#' (see `Value` section below for details).
#' Note: These objects can be large.
#' @param with_pop_params A [logical] value specifying whether population
#' level parameters should be included as an attribute entitled
#' `population_params`. Excluded by default.
#' Note: These objects can be large.
#' @param preclogy_per_iso A [logical] value. When `TRUE` and `with_pop_params`
#' is also `TRUE`, the `Parameter` column for `prec.logy` rows in
#' `population_params` will contain the antigen/isotype label (e.g.,
#' `"HlyE_IgA"`) rather than the constant `"prec.logy"`. This allows grouping
#' by `Parameter` to obtain per-isotype precision estimates directly. Default
#' is `FALSE` (all `prec.logy` rows share `Parameter = "prec.logy"`; the
#' `Iso_type` column distinguishes isotypes).
#' @returns An `sr_model` class object: a subclass of [tibble::tbl_df] that
#' contains MCMC samples from the joint posterior distribution of the model
#' parameters, conditional on the provided input `data`, 
#' including the following:
#'   - `Iteration` = Number of sampling iterations
#'   - `Chain` = Number of MCMC chains run; between 1 and 4
#'   - `Parameter` = Parameter being estimated. Includes the following:
#'     - `y0` = Posterior estimate of baseline antibody concentration
#'     - `y1` = Posterior estimate of peak antibody concentration
#'     - `t1` = Posterior estimate of time to peak
#'     - `shape` = Posterior estimate of shape parameter
#'     - `alpha` = Posterior estimate of decay rate
#'   - `Iso_type` = Antibody/antigen type combination being evaluated
#'   - `Stratification` = The variable used to stratify jags model
#'   - `Subject` = ID of subject being evaluated
#'   - `value` = Estimated value of the parameter
#' - The following [attributes] are included in the output:
#'   - `class`: Class of the output object.
#'   - `nChains`: Number of chains run.
#'   - `nParameters`: The amount of parameters estimated in the model.
#'   - `nIterations`: Number of iteration specified.
#'   - `nBurnin`: Number of burn ins.
#'   - `nThin`: Thinning number (niter/nmc).
#'   - `population_params`: Optionally included modeled population parameters,
#'   returned as a [data.frame] and excluded by default.
#'   Columns include
#'   `Iteration`, `Chain`, `Parameter`, `Iso_type`, `Stratification`, 
#'   `Population_Parameter`, and `value`.
#'     - `Population_Parameter` identifies which modeled population parameter
#'     is represented:
#'       - `mu.par` = The population means of the host-specific model
#'       parameters (on logarithmic scales). Note: y1 and shape are transformed.
#'       - `prec.par` = The population precision matrix of the
#'       hyperparameters (with diagonal elements equal to inverse variances). 
#'       The two parameters listed (separated by commas) represent the pairwise 
#'       precision relationship between specified parameters.
#'       - `prec.logy` = A vector of population precisions (inverse
#'       variances), one per antigen/isotype combination.
#'   - `priors`: A [list] that summarizes the input priors, including:
#'     - `mu_hyp_param`
#'     - `prec_hyp_param`
#'     - `omega_param`
#'     - `wishdf`
#'     - `prec_logy_hyp_param`
#'   - `fitted_residuals`: A [data.frame] containing fitted and residual values
#'   for all observations.
#'   - An optional `"jags.post"` attribute, included when argument
#'   `with_post` = TRUE.
#' @inheritDotParams prep_priors
#' @export
#' @example inst/examples/run_serodynamics-examples.R
run_serodynamics <- function(data,
                             file_mod = NULL,
                             decay_type = "power",
                             nchain = 4,
                             nadapt = 0,
                             nburn = 0,
                             nmc = 100,
                             niter = 100,
                             strat = NA,
                             with_post = FALSE,
                             with_pop_params = FALSE,
                             preclogy_per_iso = FALSE,
                             ...) {
  # Select model file based on decay type
  decay_type <- match.arg(decay_type, c("power", "exponential"))
  if (is.null(file_mod)) {
    file_mod <- if (decay_type == "power") {
      serodynamics_example("model.jags")
    } else {
      serodynamics_example("model_exp.jags")
    }
  }
   ## Build and validate the stratification list to loop through.
  strat_list <- prep_strat_list(data, strat)

  ## Creating a shell to output results
  jags_out <- tibble::tibble(
    "Iteration" = integer(),
    "Chain" = integer(),
    "value" = numeric(),
    "Subject" = character(),
    "Parameter" = character(),
    "Iso_type" = character(),
    "Stratification" = character()
  )

  ## Creating output list for jags.post
  jags_post_final <- list()

  # For loop for running stratifications
  for (i in strat_list) {
    # Creating if else statement for running the loop
    if (is.na(strat)) {
      dl_sub <- data
    } else {
      dl_sub <- data |>
        dplyr::filter(.data[[strat]] == i)
    }

    # prepare data for modeline
    longdata <- prep_data(dl_sub)
    priorspec <- prep_priors(max_antigens = longdata$n_antigen_isos,
                             ...)

    # inputs for jags model
    nchains <- nchain # nr of MC chains to run simultaneously
    nburnin <- nburn # nr of iterations to use for burn-in
    nthin <- round(niter / nmc) # thinning needed to produce nmc from niter

    tomonitor <- c("y0", "y1", "t1", "alpha", "shape")
    # Conditional statement for including population parameters
    if (with_pop_params) {
      tomonitor <- c(tomonitor, "mu.par", "prec.par",
                     "prec.logy")
    }

    jags_post <- runjags::run.jags(
      model = file_mod,
      data = c(longdata, priorspec),
      inits = initsfunction,
      method = "parallel",
      adapt = nadapt,
      burnin = nburnin,
      thin = nthin,
      sample = nmc,
      n.chains = nchains,
      monitor = tomonitor,
      summarise = FALSE
    )
    # Assigning the raw jags output to a list.
    # This object will include a raw output for the jags.post for each
    # stratification and will only be included if specified. 
    jags_post_final[[as.character(i)]] <- jags_post

    # Unpacking and cleaning MCMC output.
    jags_packed <- ggmcmc::ggs(jags_post[["mcmc"]])

    # Adding attributes
    mod_atts <- attributes(jags_packed)
    # Select necessary attributes by name for robustness across platforms
    mod_atts <- mod_atts[c("nChains", "nParameters", "nIterations",
                           "nBurnin", "nThin")]
    
    # extracting antigen-iso combinations to correctly number
    # them by the order they are estimated by the program.
    iso_dat <- tibble::tibble(
      Iso_type = attr(longdata, "antigens"),
      Subnum = as.character(seq_along(attr(longdata, "antigens")))
    )
    
    # Unpacking the mcmc object
    jags_unpacked <- unpack_jags(jags_packed)
    
    # Merging isodat in to ensure we are classifying antigen_iso.
    jags_unpacked <- dplyr::left_join(jags_unpacked, iso_dat,
                                      by = "Subnum",
                                      relationship = "many-to-one")

    # Optionally relabel prec.logy Parameter by isotype so that grouping by
    # Parameter in population_params distinguishes per-isotype precision.
    if (with_pop_params && preclogy_per_iso) {
      jags_unpacked <- relabel_preclogy_iso(jags_unpacked)
    }

    # Adding in ID name
    ids <- tibble::tibble(
      Subject_mcmc = as.character(attr(longdata, "ids")),
      Subject = as.character(seq_along(attr(longdata, "ids")))
    )
    jags_final <- reconcile_subject_ids(jags_unpacked, ids)

    # Creating a label for the stratification, if there is one.
    # If not, will add in "None".
    jags_final$Stratification <- i
    # Creating output as a data frame with the
    # jags output results for each stratification rbinded.
    jags_out <- dplyr::bind_rows(jags_out, jags_final)
  }
  
  if (with_pop_params) {
    # Preparing population parameters
    population_params <- prep_popparams(jags_out)
    population_params <- population_params[, c(
      "Iteration", "Chain", "Parameter", "Iso_type",
      "Stratification", "Population_Parameter", "value"
    )]
  
    # Taking out population parameters
    jags_out <- ex_popparams(jags_out)
  }
  
  # Making output a tibble and restructuring.
  jags_out <- jags_out[, c("Iteration", "Chain", "Parameter", "Iso_type",
                           "Stratification", "Subject", "value")]
  jags_out <- rebuild_sr_model_attributes(jags_out, mod_atts)
  
  # Adding population parameters optionally and priors in as attributes
  if (with_pop_params) {
    jags_out <- jags_out |>
      structure(population_params = population_params)
  }
  jags_out <- jags_out |>
    structure(priors = attributes(priorspec)$used_priors)
  
  # Record which decay type was used
  jags_out <- jags_out |>
    structure(decay_type = decay_type)
  
  # Calculating fitted and residuals
  fit_res <- calc_fit_mod(modeled_dat = jags_out,
                          original_data = data,
                          strat = strat)
  jags_out <- jags_out |>
    structure(fitted_residuals = fit_res)

  # Conditionally adding jags.post
  if (with_post) {
    jags_out <- jags_out |>
      structure(jags.post = jags_post_final)
  }
  return(jags_out)
}
