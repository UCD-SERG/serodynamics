#' @title Process Antibody Predictions and Compute Residuals
#' @author Kwan Ho Lee
#' @description
#' This function processes antibody predictions using JAGS posterior medians, computes residuals,
#' and prepares the dataset for model re-running. It also restores necessary attributes for compatibility.
#' 
#' @importFrom rlang .env        
#'
#' @param dat The observed dataset.
#' @param param_medians_wide A tibble with median parameter estimates from `process_jags_output()`.
#' @param file_mod Path to the JAGS model file.
#' @param strat A character string specifying the stratification variable (default: `"bldculres"`).
#' @param id A character string specifying the subject ID to filter the dataset.
#' @param antigen_iso A character string specifying the antigen identifier to filter the dataset.
#' @return A tibble with processed JAGS posterior medians for re-running the model.
#' @export
#' @example inst/examples/examples-process_antibody_predictions.R

process_antibody_predictions <- function(dat2, param_medians_wide, file_mod, strat = "bldculres", id, antigen_iso) {
  
  # Step 1: Create mapping for id
  unique_ids <- unique(dat2$id)
  subject_mapping <- data.frame(
    id = unique_ids,
    Subject = seq_along(unique_ids)
  )
  
  # Step 2: Update dataset and join subject mapping
  dat_update <- dat2 %>%
    mutate(antigen_iso = case_when(
      antigen_iso == 1 ~ "HlyE_IgA",
      antigen_iso == 2 ~ "HlyE_IgG",
      TRUE ~ as.character(antigen_iso)
    )) %>%
    left_join(subject_mapping, by = "id")
  
  # Step 3: Define the antibody decay function
  ab <- function(t, y0, y1, t1, alpha, shape) {
    beta <- log(y1 / y0) / t1
    yt <- ifelse(t <= t1, 
                 y0 * exp(beta * t), 
                 (y1^(1 - shape) - (1 - shape) * alpha * (t - t1))^(1 / (1 - shape)))
    return(yt)
  }
  
  # Step 4: Filter specific subject using the input arguments
  dat_update <- dat_update %>% 
    filter(id == .env$id, antigen_iso == .env$antigen_iso)
  
  # Step 5: Compute predicted results
  dat_update <- dat_update %>%
    left_join(param_medians_wide, by = c("id", "antigen_iso")) %>%
    rowwise() %>%
    mutate(predicted_result = ab(dayssincefeveronset, y0, y1, t1, alpha, shape)) %>%
    ungroup()
  
  # Step 6: Compute residuals and reorganize data
  dat_resid <- dat_update %>%
    mutate(
      residual = result - predicted_result,       # Regular residual
      abs_residual = abs(result - predicted_result) # Absolute residual
    ) %>%
    select(Country, id, sample_id, bldculres, antigen_iso, studyvisit, 
           dayssincefeveronset, visit_num, result, predicted_result, residual, abs_residual)
  
  # Step 7: Prepare data for run_mod by keeping only abs_residual as result
  dat_resid_modified <- dat_resid %>%
    select(-result, -predicted_result, -residual) %>%
    rename(result = abs_residual) %>%
    select(Country, id, sample_id, bldculres, antigen_iso, studyvisit, 
           dayssincefeveronset, result, visit_num)
  
  # Step 8: Restore attributes
  restore_attributes <- function(dat_target, dat_reference) {
    attrs_to_restore <- c("id_var", "biomarker_var", "timeindays", "value_var")
    for (attr_name in attrs_to_restore) {
      if (!is.null(attributes(dat_reference)[[attr_name]])) {
        attributes(dat_target)[[attr_name]] <- attributes(dat_reference)[[attr_name]]
      }
    }
    class(dat_target) <- class(dat_reference)
    return(dat_target)
  }
  
  dat_resid_modified <- restore_attributes(dat_resid_modified, dat)
  
  # Step 9: Run JAGS model again using processed data
  jags_post2 <- run_mod(
    data = dat_resid_modified,
    file_mod = file_mod,
    nchain = 2,
    nadapt = 100,
    nburn = 100,
    nmc = 500,
    niter = 1000,
    strat = strat
  )
  
  # Step 10: Process JAGS output for re-run model; here we run until step 7 so that an id column is added
  param_medians_wide_2 <- process_jags_output(jags_post2, dataset = dat2, run_until = 7)
  
  return(param_medians_wide_2)
}
