#' @title Process JAGS Output to Extract Full MCMC Samples for a Specific 
#' Subject and Antigen
#' @description
#' Simplified version that pulls directly from `model$curve_params`(the element 
#' created by `run_mod(include_subs = TRUE)`), filters to the desired subject 
#' and antigen_iso, and returns a wide tibble of MCMC samples.  
#'
#' @param jags_post The list returned by `run_mod(...)` 
#' (must have `curve_params`).
#' @param dataset      A data.frame containing original data.
#' @param id           The original subject ID (e.g. "sees_npl_128") to extract.
#' @param antigen_iso  The antigen to extract, e.g. "HlyE_IgA" or "HlyE_IgG".
#' @return A tibble, one row per MCMC iteration & chain, wide format giving 
#' each parameter.
#' @export
process_jags_samples <- function(jags_post, dataset, id, antigen_iso) {
  # --------------------------------------------------------------------------
  # 1) Grab the curve_params data.frame out of the run_mod() output:
  df <- jags_post$curve_params

  
  # --------------------------------------------------------------------------
  # 2) Filter to the subject & antigen of interest:
  df_sub   <- df |>
    dplyr::filter(
      .data$Subject == id,        # e.g. "sees_npl_128"
      .data$Iso_type == antigen_iso  # e.g. "HlyE_IgA"
    )
  
  # --------------------------------------------------------------------------
  # 3) Clean up parameter name if you like:
  df_clean <- df_sub |>
    dplyr::mutate(
      Parameter_clean = stringr::str_extract(.data$Parameter, "^[^\\[]+")
    )
  
  # --------------------------------------------------------------------------
  # 4) Pivot to wide format: one row per iteration/chain
  samples_wide <- df_clean |>
    dplyr::select(
      all_of(c("Chain",
               "Iteration",
               "Iso_type",
               "Parameter_clean",
               "value"))
    ) |>
    tidyr::pivot_wider(
      names_from  = c("Parameter_clean"),
      values_from = c("value")
    ) |>
    dplyr::arrange(.data$Chain, .data$Iteration) |>
    
    dplyr::mutate(
      antigen_iso = factor(.data$Iso_type),
      r = .data$shape
    ) |>
    dplyr::select(-c("Iso_type"))

  
  return(samples_wide)
}
