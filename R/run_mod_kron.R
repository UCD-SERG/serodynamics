#' @title Run the Kronecker (correlated biomarkers) model
#' @author Kwan Ho Lee
#' @description
#'  `run_mod_kron()` is a convenience wrapper to fit the Chapter 2
#'  Kronecker model while keeping the same output shape as
#'  [`serodynamics::run_mod()`]. It prepares the data, combines the base
#'  priors with Kronecker priors, and calls **runjags**.
#'
#'  Required helpers available in the package environment:
#'  - `prep_data()`, `prep_priors()`, and `calc_fit_mod()`.
#'
#' @param data A long table (like from `as_case_data()`), consumed by 
#' `prep_data()`.
#' @param file_mod Path to the JAGS model file. Use `write_model_ch2_kron()` 
#' to generate it.
#' @param nchain,nadapt,nburn,nmc,niter MCMC settings (same semantics as 
#' `run_mod()`).
#' @param strat Optional column name to stratify by (same behavior as 
#' `run_mod()`).
#' @param with_post Logical; when `TRUE`, attaches raw `jags.post` in the 
#' output attributes.
#' @param monitor Character vector of nodes to monitor. Defaults to core 
#' parameters
#'  plus `TauB` and `TauP`.
#' @param ... Additional arguments passed to `prep_priors()` 
#' (e.g. `mu_hyp_param`).
#'
#' @return A tibble with the same general structure as `run_mod()` output, with
#'  attributes carrying priors used, MCMC metadata, fitted values, and 
#'  optionally `jags.post`.
#'
#' @export
#' @example inst/examples/examples-run_mod_kron.R
run_mod_kron <- function(data,
                         file_mod = "model_ch2_kron.jags",
                         nchain = 4, nadapt = 0, nburn = 0,
                         nmc = 100, niter = 100,
                         strat = NA, with_post = FALSE,
                         monitor = c("y0", "y1", "t1", "alpha", "shape", 
                                     "TauB", "TauP"),
                         ...) {
  
  if (is.na(strat)) {
    strat_list <- "None"
  } else {
    strat_list <- unique(data[[strat]])
  }
  
  jags_out <- data.frame(
    Iteration = NA_integer_, Chain = NA_integer_, Parameter = NA_character_, 
    value = NA_real_,
    Parameter_sub = NA_character_, Subject = NA_character_, 
    Iso_type = NA_character_,
    Stratification = NA_character_
  )
  jags_post_final <- list()
  
  for (i in strat_list) {
    
    dl_sub <- if (is.na(strat)) data else dplyr::filter(data, 
                                                        .data[[strat]] == i)
    
    longdata    <- prep_data(dl_sub)
    base_priors <- prep_priors(max_antigens = longdata$n_antigen_isos, ...)
    base_priors <- serodynamics:::clean_priors(base_priors)
    kron_priors <- serodynamics:::prep_priors_multiB(B = 
                                                       longdata$n_antigen_isos)
    
    # JAGS needs B as a scalar
    B_scalar <- list(B = longdata$n_antigen_isos)
    
    priorspec <- c(base_priors, kron_priors, B_scalar)
    
    nchains <- nchain
    nburnin <- nburn
    nthin   <- max(1L, round(niter / nmc))
    
    jags_post <- runjags::run.jags(
      model     = file_mod,
      data      = c(longdata, priorspec),
      inits     = function(chain) serodynamics:::inits_kron(chain),
      method    = "parallel",
      adapt     = nadapt, burnin = nburnin, thin = nthin,
      sample    = nmc, n.chains = nchains,
      monitor   = monitor,
      summarise = FALSE
    )
    jags_post_final[[i]] <- jags_post
    
    jags_unpack <- ggmcmc::ggs(jags_post[["mcmc"]])
    mod_atts <- attributes(jags_unpack)[4:8]
    
    iso_dat <- attributes(longdata)$antigens |>
      as.data.frame() |>
      tibble::rownames_to_column(var = "Subnum") |>
      dplyr::mutate(Subnum = as.numeric(.data$Subnum))
    
    jags_unpack <- jags_unpack |>
      dplyr::mutate(
        Subnum        = sub(".*,", "", .data$Parameter),
        Parameter_sub = sub("\\[.*", "", .data$Parameter),
        Subject       = sub("\\,.*", "", .data$Parameter)
      ) |>
      dplyr::mutate(
        Subnum  = as.numeric(sub("\\].*", "", .data$Subnum)),
        Subject = sub(".*\\[", "", .data$Subject)
      ) |>
      dplyr::left_join(iso_dat, by = "Subnum")
    
    ids <- data.frame(attr(longdata, "ids")) |>
      dplyr::mutate(Subject = as.character(dplyr::row_number()))
    
    jags_final <- jags_unpack |>
      dplyr::left_join(ids, by = "Subject") |>
      dplyr::select(!c("Subnum", "Subject")) |>
      dplyr::rename(
        Iso_type = tidyselect::all_of("attributes.longdata..antigens"),
        Subject  = tidyselect::all_of("attr.longdata...ids..")
      )
    
    jags_final$Stratification <- i
    jags_out <- data.frame(rbind(jags_out, jags_final))
  }
  
  jags_out <- jags_out[stats::complete.cases(jags_out), ]
  jags_out <- dplyr::as_tibble(jags_out) |>
    dplyr::select(-tidyselect::all_of("Parameter")) |>
    dplyr::rename(Parameter = tidyselect::all_of("Parameter_sub")) |>
    dplyr::select(
      tidyselect::all_of(c(
        "Iteration", "Chain", "Parameter", "Iso_type",
        "Stratification", "Subject", "value"
      )),
      tidyselect::everything()
    )
  
  
  attributes(jags_out) <- c(attributes(jags_out), mod_atts)
  
  # Attach priors used (from last stratum)
  jags_out <- jags_out |> structure("priors" 
                                    = attributes(priorspec)$used_priors)
  
  fit_res <- calc_fit_mod(modeled_dat = jags_out, original_data = dl_sub)
  jags_out <- jags_out |> structure(fitted_residuals = fit_res)
  
  if (with_post) jags_out <- jags_out |> structure(jags.post = jags_post_final)
  
  class(jags_out) <- union("sr_model", class(jags_out))
  jags_out
}
