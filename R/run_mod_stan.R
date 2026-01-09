#' @title Run Stan Model
#' @author Sam Schildhauer, GitHub Copilot
#' @description
#'  `run_mod_stan()` takes a data frame and adjustable MCMC inputs to fit a
#'  Bayesian model using Stan (via cmdstanr) to estimate antibody dynamic 
#'  curve parameters. The model estimates seroresponse dynamics to an
#'  infection. The antibody dynamic curve includes the following parameters:
#'  - y0 = baseline antibody concentration
#'  - y1 = peak antibody concentration
#'  - t1 = time to peak
#'  - shape = shape parameter
#'  - alpha = decay rate
#' @param data A [base::data.frame()] with the required columns (see details).
#' @param file_mod The name of the file that contains model structure 
#' (a .stan file).
#' @param nchain An [integer] between 1 and 4 that specifies
#' the number of MCMC chains to be run per Stan model.
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
  
  ## Conditionally creating a stratification list to loop through
  if (is.na(strat)) {
    strat_list <- "None"
  } else {
    strat_list <- unique(data[[strat]])
  }
  
  ## Creating a shell to output results
  stan_out <- data.frame(
    "Iteration" = NA,
    "Chain" = NA,
    "Parameter" = NA,
    "value" = NA,
    "Parameter_sub" = NA,
    "Subject" = NA,
    "Iso_type" = NA,
    "Stratification" = NA
  )
  
  ## Creating output list for stan fit objects
  stan_fit_final <- list()
  
  # For loop for running stratifications
  for (i in strat_list) {
    # Creating if else statement for running the loop
    if (is.na(strat)) {
      dl_sub <- data
    } else {
      dl_sub <- data |>
        dplyr::filter(.data[[strat]] == i)
    }
    
    # prepare data for modeling
    longdata <- prep_data_stan(dl_sub)
    priorspec <- prep_priors_stan(max_antigens = longdata$n_antigen_isos, ...)
    
    # Combine data and priors for Stan
    stan_data <- c(longdata, priorspec)
    
    # Compile and fit the Stan model
    mod <- cmdstanr::cmdstan_model(file_mod)
    
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
    stan_fit_final[[i]] <- stan_fit
    
    # Extract samples and convert to ggmcmc format
    draws <- stan_fit$draws(
      variables = c("y0", "y1", "t1", "alpha", "shape"),
      format = "draws_array"
    )
    
    # Convert to mcmc.list format compatible with ggmcmc
    mcmc_list <- list()
    for (ch in 1:nchain) {
      mcmc_list[[ch]] <- coda::as.mcmc(draws[ch, , ])
    }
    mcmc_list <- coda::as.mcmc.list(mcmc_list)
    
    # Use ggmcmc to process
    stan_unpack <- ggmcmc::ggs(mcmc_list)
    
    # Adding attributes
    mod_atts <- attributes(stan_unpack)
    # Only keeping necessary attributes
    mod_atts <- mod_atts[4:8]
    
    # extracting antigen-iso combinations
    iso_dat <- data.frame(attributes(longdata)$antigens)
    iso_dat <- iso_dat |> dplyr::mutate(Subnum = as.numeric(row.names(iso_dat)))
    
    # Working with stan unpacked ggs outputs to clarify parameter and subject
    stan_unpack <- stan_unpack |>
      dplyr::mutate(
        Subnum = sub(".*,", "", .data$Parameter),
        Parameter_sub = sub("\\[.*", "", .data$Parameter),
        Subject = sub("\\,.*", "", .data$Parameter)
      ) |>
      dplyr::mutate(
        Subnum = as.numeric(sub("\\].*", "", .data$Subnum)),
        Subject = sub(".*\\[", "", .data$Subject)
      )
    
    # Merging isodat
    stan_unpack <- dplyr::left_join(stan_unpack, iso_dat, by = "Subnum")
    ids <- data.frame(attr(longdata, "ids")) |>
      mutate(Subject = as.character(dplyr::row_number()))
    stan_unpack <- dplyr::left_join(stan_unpack, ids, by = "Subject")
    
    stan_final <- stan_unpack |>
      dplyr::select(!c("Subnum", "Subject")) |>
      dplyr::rename(
        c("Iso_type" = "attributes.longdata..antigens",
          "Subject" = "attr.longdata...ids..")
      )
    
    # Creating a label for the stratification
    stan_final$Stratification <- i
    
    ## Creating output
    stan_out <- data.frame(rbind(stan_out, stan_final))
  }
  
  # Ensuring output does not have any NAs
  stan_out <- stan_out[complete.cases(stan_out), ]
  
  # Making output a tibble and restructuring
  stan_out <- dplyr::as_tibble(stan_out) |>
    select(!c("Parameter")) |>
    rename("Parameter" = "Parameter_sub")
  stan_out <- stan_out[, c("Iteration", "Chain", "Parameter", "Iso_type",
                           "Stratification", "Subject", "value")]
  
  current_atts <- attributes(stan_out)
  current_atts <- c(current_atts, mod_atts)
  attributes(stan_out) <- current_atts
  
  # Adding priors
  stan_out <- stan_out |>
    structure("priors" = attributes(priorspec)$used_priors)
  
  # Calculating fitted and residuals
  fit_res <- calc_fit_mod(modeled_dat = stan_out,
                          original_data = dl_sub)
  stan_out <- stan_out |>
    structure(fitted_residuals = fit_res)
  
  # Conditionally adding stan fit
  if (with_post) {
    stan_out <- stan_out |>
      structure(stan.fit = stan_fit_final)
  }
  
  stan_out <- stan_out |>
    structure(class = union("sr_model", class(stan_out)))
  
  stan_out
}
