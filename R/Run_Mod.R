#' @title Run Jags Model
#' @author Sam Schildhauer
#' @description
#'  `run_mod()` takes a data frame and adjustable MCMC inputs to
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
#' @param with_post A [logical] value specifying whether a raw `jags.post`
#' component
#' should be included as an element of the [list] object returned by `run_mod()`
#' (see `Value` section below for details).
#' Note: These objects can be large.
#' @returns An `sr_model` class object: a subclass of [dplyr::tbl_df] that
#' contains MCMC samples from the joint posterior distribution of the model
#' parameters, conditional on the provided input `data`, 
#' including the following:
#'   - `iteration` = Number of sampling iterations
#'   - `chain` = Number of MCMC chains run; between 1 and 4
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
#'   - `nChain`: Number of chains run.
#'   - `nParameters`: The amount of parameters estimated in the model.
#'   - `nIterations`: Number of iteration specified.
#'   - `nBurnin`: Number of burn ins.
#'   - `nThin`: Thinning number (niter/nmc).
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
#'   - `population_params`: A [dplyr::tbl_df] with posterior samples of the
#'   population-level parameters (`mu.par`), transformed to the original
#'   parameter scale.  Columns: `Chain`, `Iteration`, `antigen_iso`, `y0`,
#'   `y1`, `t1`, `alpha`, `shape`, `Stratification`.
#' @inheritDotParams prep_priors
#' @export
#' @example inst/examples/run_mod-examples.R
run_mod <- function(data,
                    file_mod = serodynamics_example("model.jags"),
                    nchain = 4,
                    nadapt = 0,
                    nburn = 0,
                    nmc = 100,
                    niter = 100,
                    strat = NA,
                    with_post = FALSE,
                    ...) {
  ## Conditionally creating a stratification list to loop through
  if (is.na(strat)) {
    strat_list <- "None"
  } else {
    strat_list <- unique(data[[strat]])
  }

  ## Creating a shell to output results
  jags_out <- data.frame(
    "Iteration" = NA,
    "Chain" = NA,
    "Parameter" = NA,
    "value" = NA,
    "Parameter_sub" = NA,
    "Subject" = NA,
    "Iso_type" = NA,
    "Stratification" = NA
  )

  ## Creating output list for jags.post
  jags_post_final <- list()

  ## Creating a shell to accumulate population-level (mu.par) parameter samples
  pop_params_out <- data.frame(
    "Chain" = NA_integer_,
    "Iteration" = NA_integer_,
    "antigen_iso" = NA_character_,
    "y0" = NA_real_,
    "y1" = NA_real_,
    "t1" = NA_real_,
    "alpha" = NA_real_,
    "shape" = NA_real_,
    "Stratification" = NA_character_
  )

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
    nadapt <- nadapt # nr of iterations for adaptation
    nburnin <- nburn # nr of iterations to use for burn-in
    nmc <- nmc # nr of samples in posterior chains
    niter <- niter # nr of iterations for posterior sample
    nthin <- round(niter / nmc) # thinning needed to produce nmc from niter

    tomonitor <- c("y0", "y1", "t1", "alpha", "shape", "mu.par")

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
    jags_post_final[[i]] <- jags_post

    # Unpacking and cleaning MCMC output.
    jags_unpack <- ggmcmc::ggs(jags_post[["mcmc"]])

    # Capture model-level metadata attributes from ggmcmc before any filtering.
    # We want nChains, nParameters, nIterations, nBurnin, nThin (indices 4–8).
    mod_atts_raw <- attributes(jags_unpack)[4:8]

    # Extract and process population-level (mu.par) parameter samples.
    # mu.par[iso, param_idx]: iso is first index, param index is second.
    mu_par_rows <- jags_unpack |>
      dplyr::filter(grepl("^mu\\.par\\[", .data$Parameter))

    if (nrow(mu_par_rows) > 0) {
      antigen_iso_labels <- attributes(longdata)$antigens
      param_names <- c(
        "1" = "y0_log",
        "2" = "y1_increment_log",
        "3" = "t1_log",
        "4" = "alpha_log",
        "5" = "shape_minus1_log"
      )
      mu_par_processed <- mu_par_rows |>
        dplyr::mutate(
          antigen_iso_idx = as.integer(
            sub("^mu\\.par\\[(\\d+),.*", "\\1", .data$Parameter)
          ),
          param_idx = as.character(
            sub("^mu\\.par\\[\\d+,(\\d+)\\]", "\\1", .data$Parameter)
          )
        ) |>
        dplyr::mutate(
          antigen_iso = factor(
            .data$antigen_iso_idx,
            labels = antigen_iso_labels
          ),
          param_name = unname(param_names[.data$param_idx])
        ) |>
        dplyr::select(
          all_of(c("Chain", "Iteration", "antigen_iso", "param_name", "value"))
        ) |>
        tidyr::pivot_wider(
          names_from = "param_name",
          values_from = "value"
        ) |>
        dplyr::mutate(
          y0 = exp(.data$y0_log),
          y1 = .data$y0 + exp(.data$y1_increment_log),
          t1 = exp(.data$t1_log),
          alpha = exp(.data$alpha_log),
          shape = exp(.data$shape_minus1_log) + 1,
          Stratification = i,
          antigen_iso = as.character(.data$antigen_iso)
        ) |>
        dplyr::select(
          -all_of(
            c(
              "y0_log",
              "y1_increment_log",
              "t1_log",
              "alpha_log",
              "shape_minus1_log"
            )
          )
        )
      pop_params_out <- rbind(pop_params_out, mu_par_processed)
    }

    # Remove mu.par rows before further processing (existing code expects only
    # subject/iso-indexed parameters such as y0, y1, t1, alpha, shape).
    jags_unpack <- jags_unpack |>
      dplyr::filter(!grepl("^mu\\.par\\[", .data$Parameter))

    # Adjust nParameters so it reflects only the subject/iso-level scalars,
    # not the mu.par hyperparameter scalars.
    n_mu_par_params <- length(unique(mu_par_rows$Parameter))
    mod_atts <- mod_atts_raw
    mod_atts$nParameters <-
      mod_atts_raw$nParameters - as.integer(n_mu_par_params)

    # extracting antigen-iso combinations to correctly number
    # then by the order they are estimated by the program.
    iso_dat <- data.frame(attributes(longdata)$antigens)
    iso_dat <- iso_dat |> dplyr::mutate(Subnum = as.numeric(row.names(iso_dat)))
    # Working with jags unpacked ggs outputs to clarify parameter and subject
    jags_unpack <- jags_unpack |>
      dplyr::mutate(
        Subnum = sub(".*,", "", .data$Parameter),
        Parameter_sub = sub("\\[.*", "", .data$Parameter),
        Subject = sub("\\,.*", "", .data$Parameter)
      ) |>
      dplyr::mutate(
        Subnum = as.numeric(sub("\\].*", "", .data$Subnum)),
        Subject = sub(".*\\[", "", .data$Subject)
      )
    # Merging isodat in to ensure we are classifying antigen_iso
    jags_unpack <- dplyr::left_join(jags_unpack, iso_dat, by = "Subnum")
    ids <- data.frame(attr(longdata, "ids")) |>
      mutate(Subject = as.character(dplyr::row_number()))
    jags_unpack <- dplyr::left_join(jags_unpack, ids, by = "Subject")
    jags_final <- jags_unpack |>
      dplyr::select(!c("Subnum", "Subject")) |>
      dplyr::rename(c("Iso_type" = "attributes.longdata..antigens",
                      "Subject" = "attr.longdata...ids.."))
    # Creating a label for the stratification, if there is one.
    # If not, will add in "None".
    jags_final$Stratification <- i
    ## Creating output
    jags_out <- data.frame(rbind(jags_out, jags_final))
  }
  # Ensuring output does not have any NAs
  jags_out <- jags_out[complete.cases(jags_out), ]
  # Outputting the finalized jags output as a data frame with the
  # jags output results for each stratification rbinded.

  # Making output a tibble and restructing.
  jags_out <- dplyr::as_tibble(jags_out)  |>
    select(!c("Parameter")) |>
    rename("Parameter" = "Parameter_sub")
  jags_out <- jags_out[, c("Iteration", "Chain", "Parameter", "Iso_type",
                           "Stratification", "Subject", "value")]
  current_atts <- attributes(jags_out) 
  current_atts <- c(current_atts, mod_atts)
  attributes(jags_out) <- current_atts
  
  # Adding priors
  jags_out <- jags_out |>
    structure("priors" = attributes(priorspec)$used_priors)
  
  # Attaching population-level (mu.par) parameter samples as an attribute
  pop_params_out <- pop_params_out[complete.cases(pop_params_out), ]
  pop_params_out <- dplyr::as_tibble(pop_params_out)
  jags_out <- jags_out |>
    structure(population_params = pop_params_out)
  
  # Calculating fitted and residuals
  # Renaming columns using attributes from as_case_data
  fit_res <- calc_fit_mod(modeled_dat = jags_out,
                          original_data = dl_sub)
  jags_out <- jags_out |>
    structure(fitted_residuals = fit_res)

  # Conditionally adding jags.post
  if (with_post) {
    jags_out <- jags_out |>
      structure(jags.post = jags_post_final)
  }
  jags_out <- jags_out |>
    structure(class = union("sr_model", class(jags_out)))
  jags_out
}
