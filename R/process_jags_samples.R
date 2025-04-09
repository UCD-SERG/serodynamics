#' @title Process JAGS Output to Extract Full MCMC Samples for a Specific Subject and Antigen
#' @description
#' This function extracts the full posterior parameter samples from a JAGS model run for a specified
#' subject (using the original subject ID) and antigen. The returned tibble is in wide format
#' (each row corresponds to one MCMC sample) so that you can compute quantiles (e.g., 10%, 50%, 90%)
#' to form credible interval bands.
#'
#' @param jags_post A list output from `serodynamics::run_mod()`, containing posterior samples.
#' @param dataset A data.frame containing subject and antigen information.
#' @param id The original subject ID (as in the dataset) for which you want to extract samples.
#' @param antigen_iso A numeric or character value specifying the antigen iso.
#'   If a character, it should be one of "HlyE_IgA" or "HlyE_IgG".
#' @return A tibble in wide format with one row per MCMC sample. Columns correspond to the parameters
#'   (e.g., y0, y1, t1, alpha, shape) needed to compute the antibody curve.
#' @export
process_jags_samples <- function(jags_post, dataset, id, antigen_iso) {
  # Step 1: Filter dataset for the "typhi" group.
  data_typhi <- dataset %>% 
    dplyr::filter(bldculres == "typhi")
  
  # Step 2: Create a mapping between the original subject id and the internal Subject number.
  unique_ids <- unique(data_typhi$id)
  subject_mapping <- data.frame(
    id = unique_ids,
    Subject = seq_along(unique_ids)
  )
  
  # Step 3: Unpack the JAGS posterior samples into a tidy data frame.
  jags_unpack <- ggmcmc::ggs(jags_post$jags.post$typhi$mcmc)
  
  # Step 4: Extract parameter name, internal Subject number, and antigen_iso code.
  jags_processed <- jags_unpack %>%
    dplyr::mutate(
      Parameter_clean = stringr::str_extract(Parameter, "^[a-zA-Z0-9]+"),
      Subject = as.numeric(stringr::str_extract(Parameter, "(?<=\\[)\\d+")),
      antigen_iso_num = as.numeric(stringr::str_extract(Parameter, "(?<=,)\\d+(?=\\])"))
    ) %>%
    dplyr::filter(!is.na(Parameter_clean))
  
  # Step 5: Map antigen_iso if provided as character.
  antigen_map <- c("HlyE_IgA" = 1, "HlyE_IgG" = 2)
  if (is.character(antigen_iso)) {
    antigen_iso_val <- antigen_map[[antigen_iso]]
  } else {
    antigen_iso_val <- antigen_iso
  }
  
  # Step 6: Merge the subject mapping into the JAGS processed data to add the original id.
  jags_with_id <- jags_processed %>%
    dplyr::left_join(subject_mapping, by = "Subject")
  
  # Step 7: Filter for the specified original subject id and antigen_iso.
  jags_filtered <- jags_with_id %>%
    dplyr::filter(id == !!id, antigen_iso_num == antigen_iso_val)
  
  # Step 8: Reshape into wide format so that each row is one MCMC sample with columns for each parameter.
  samples_wide <- jags_filtered %>%
    dplyr::select(Chain, Iteration, Parameter_clean, value) %>% 
    tidyr::pivot_wider(names_from = Parameter_clean, values_from = value)
  
  return(samples_wide)
}

