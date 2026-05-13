#' @title Run Stan Model
#' @description
#'  `run_mod_stan()` takes a data frame and adjustable MCMC inputs to fit a
#'  Bayesian model using Stan (via cmdstanr) to estimate antibody dynamic 
#'  curve parameters. The model estimates seroresponse dynamics to an
#'  infection. The antibody dynamic curve includes the following parameters:
#'  - y0 = baseline antibody concentration
#'  - y1 = peak antibody concentration
#'  - t1 = time to peak
#'  - alpha = decay rate
#'  - shape = shape parameter
#' @param data A [base::data.frame()] with the required columns (see details).
#' @param file_mod The name of the file that contains model structure 
#' (a .stan file).
#' @param nchain A positive [integer] specifying the number of MCMC chains 
#' to be run per Stan model.
#' @param nadapt An [integer] specifying the number of warmup/adaptation 
#' iterations per chain (Stan equivalent of JAGS adapt + burnin).
#' @param niter An [integer] specifying the number of post-warmup iterations.
#' @param strat A [character] string specifying the stratification variable,
#' entered in quotes.
#' @param with_post A [logical] value specifying whether a raw `stan_fit`
#' component should be included as an element of the [list] object returned 
#' by `run_mod_stan()` (see `Value` section below for details).
#' Note: These objects can be large.
#' @param ... Additional arguments passed to `prep_priors_stan()`.
#' @returns An `sr_model` class object: a subclass of [dplyr::tbl_df] that
#' contains MCMC samples from the joint posterior distribution of the model
#' parameters, conditional on the provided input `data`, 
#' including the same structure as `run_mod()`.
#' @inheritDotParams prep_priors_stan
#' @export
#' @example inst/examples/run_mod_stan-examples.R
run_mod_stan <- function(data,
                         file_mod = serodynamics_example("model.stan"),
                         nchain = 4,
                         nadapt = 1000,
                         niter = 1000,
                         strat = NA,
                         with_post = FALSE,
                         ...) {
  
  # Check if cmdstanr is available
  if (!requireNamespace("cmdstanr", quietly = TRUE)) {
    cli::cli_abort(
      c(
        "Package {.pkg cmdstanr} is required but not installed.",
        "i" = paste0(
          "Install it with: ",
          "{.code install.packages('cmdstanr', ",
          "repos = c('https://stan-dev.r-universe.dev', ",
          "getOption('repos')))}"
        )
      )
    )
  }
  
  # Validate nchain
  if (!is.numeric(nchain) || length(nchain) != 1 || nchain < 1 || 
      nchain != as.integer(nchain)) {
    cli::cli_abort(
      c(
        "{.arg nchain} must be a positive integer.",
        "x" = "You provided: {.val {nchain}}"
      )
    )
  }
  
  ## Setup stratification
  strat_list <- setup_stratification(data, strat)
  
  # Handle case where all strat values are NA (empty strat_list)
  if (length(strat_list) == 0) {
    cli::cli_abort(
      c(
        "All values in stratification column are NA.",
        "i" = paste(
          "Either provide a valid stratification column",
          "or use {.arg strat = NA}."
        )
      )
    )
  }
  
  ## Create output shell
  stan_out <- create_output_shell()
  
  ## Creating output list for stan fit objects
  stan_fit_final <- list()
  
  ## Create shell for fitted/residuals
  fit_res_combined <- data.frame()
  
  # Compile Stan model once (outside loop to avoid recompilation)
  mod <- cmdstanr::cmdstan_model(file_mod)
  
  # For loop for running stratifications
  # Track first stratum's dimensions for validation
  first_n_antigen_isos <- NULL
  first_antigens <- NULL
  
  for (i in strat_list) {
    # Filter data by stratification
    dl_sub <- filter_by_stratification(data, strat, i)
    
    # prepare data for modeling
    longdata <- prep_data_stan(dl_sub)
    priorspec <- prep_priors_stan(max_antigens = longdata$n_antigen_isos, ...)
    
    # For stratified runs, validate that dimensions are consistent across strata
    # This is critical because we store only one set of priors/attributes
    if (is.null(first_n_antigen_isos)) {
      first_n_antigen_isos <- longdata$n_antigen_isos
      first_antigens <- attr(longdata, "antigens")
    } else {
      current_antigens <- attr(longdata, "antigens")
      if (longdata$n_antigen_isos != first_n_antigen_isos ||
            !identical(current_antigens, first_antigens)) {
        cli::cli_abort(
          c(
            "Inconsistent antigen dimensions across strata.",
            "i" = paste(
              "First stratum has {first_n_antigen_isos} antigens:",
              "{paste(first_antigens, collapse = ', ')}"
            ),
            "i" = paste(
              "Current stratum '{i}' has {longdata$n_antigen_isos} antigens:",
              "{paste(current_antigens, collapse = ', ')}"
            ),
            "i" = paste(
              "All strata must have the same antigens in the same order",
              "for stratified Stan models."
            )
          )
        )
      }
    }
    
    # Combine data and priors for Stan
    # Remove n_params from priorspec to avoid duplicate (already in longdata)
    priorspec_clean <- priorspec[names(priorspec) != "n_params"]
    stan_data <- c(longdata, priorspec_clean)
    
    # Fit the Stan model (model already compiled)
    stan_fit <- mod$sample(
      data = stan_data,
      chains = nchain,
      parallel_chains = nchain,
      iter_warmup = nadapt,
      iter_sampling = niter,
      refresh = 0,  # Suppress iteration messages
      show_messages = FALSE
    )
    
    # Store raw Stan fit if requested
    if (with_post) {
      stan_fit_final[[as.character(i)]] <- stan_fit
    }
    
    # Extract samples and convert to ggmcmc format
    draws <- stan_fit$draws(
      variables = c("y0", "y1", "t1", "alpha", "shape"),
      format = "draws_array"
    )
    
    # Convert to mcmc.list format compatible with ggmcmc
    # draws_array has dimensions [iteration, chain, variable]
    mcmc_list <- list()
    for (ch in 1:nchain) {
      mcmc_list[[ch]] <- coda::as.mcmc(draws[, ch, ])
    }
    mcmc_list <- coda::as.mcmc.list(mcmc_list)
    
    # Use ggmcmc to process
    stan_unpack <- ggmcmc::ggs(mcmc_list)
    
    # Adding attributes - select by name for robustness
    mod_atts <- attributes(stan_unpack)
    # Keep only the attributes needed for downstream processing
    needed_atts <- c(
      "nChains", "nParameters", "nIterations", "nBurnin", "nThin"
    )
    mod_atts <- mod_atts[names(mod_atts) %in% needed_atts]
    
    # Process MCMC output to add antigen-iso and subject information
    stan_final <- process_mcmc_output(stan_unpack, longdata, i)
    
    # Calculate fitted and residuals for this stratum
    # Rename Parameter_sub to Parameter before calc_fit_mod
    stan_final_for_fit <- stan_final |>
      dplyr::select(!c("Parameter")) |>
      dplyr::rename("Parameter" = "Parameter_sub")
    
    fit_res_stratum <- calc_fit_mod(
      modeled_dat = stan_final_for_fit,
      original_data = dl_sub
    )
    
    # Combine fitted/residuals across strata
    fit_res_combined <- dplyr::bind_rows(fit_res_combined, fit_res_stratum)
    
    ## Creating output
    stan_out <- data.frame(rbind(stan_out, stan_final))
  }
  
  # Remove NAs before final processing
  stan_out <- stan_out[complete.cases(stan_out), ]
  
  # Rename Parameter_sub to Parameter for final output
  stan_out <- stan_out |>
    dplyr::select(!c("Parameter")) |>
    dplyr::rename("Parameter" = "Parameter_sub")
  
  # Format final output with combined fitted/residuals
  stan_out <- format_model_output(
    model_out = stan_out,
    mod_atts = mod_atts,
    priorspec = priorspec,
    fit_res = fit_res_combined,
    post_fit = stan_fit_final,
    with_post = with_post,
    post_attr_name = "stan.fit"
  )
  
  # Attach antigens and ids attributes for sample_predictive_stan()
  attr(stan_out, "antigens") <- attr(longdata, "antigens")
  attr(stan_out, "ids") <- attr(longdata, "ids")
  
  stan_out
}
