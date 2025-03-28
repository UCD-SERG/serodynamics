#' @title Finalize JAGS Output by Mapping and Filtering
#' @author 
#'   Kwan Ho Lee
#' @description
#' This function finalizes the output of the basic JAGS processing by mapping the
#' subject numbers back to the original subject IDs and then filtering the data for a 
#' specified subject ID and antigen. It completes steps 8–9 of the overall processing.
#'
#' @importFrom rlang .env
#'
#' @param basic_output A tibble output from `process_jags_basic()`.
#' @param dataset A [data.frame] containing subject and antigen information.
#' @param id A parameter specifying the subject ID for filtering.
#' @param antigen_iso A parameter specifying the antigen identifier (e.g., "HlyE_IgA" or "HlyE_IgG") for filtering.
#' @return A tibble with the filtered median parameter estimates for the specified subject and antigen.
#' @export
#' @example inst/examples/examples-finalize_jags_output.R
finalize_jags_output <- function(basic_output, dataset, id, antigen_iso) {
  # Check if required arguments are provided
  if (is.null(id) || is.null(antigen_iso)) {
    stop("Please provide both 'id' and 'antigen_iso' arguments.")
  }
  
  # Step 8: Filter dataset for rows where bldculres is "typhi" and build a subject mapping
  data_typhi <- dataset %>% 
    dplyr::filter(bldculres == "typhi")
  unique_ids <- unique(data_typhi$id)
  subject_mapping <- data.frame(
    id = unique_ids,
    Subject = seq_along(unique_ids)
  )
  
  # Merge the subject mapping with the basic output from steps 1–7
  merged_output <- basic_output %>%
    dplyr::left_join(subject_mapping, by = "Subject")
  
  # Step 9: Filter the merged data for the specified id and antigen_iso
  final_output <- merged_output %>%
    dplyr::filter(id == .env$id, antigen_iso == .env$antigen_iso)
  
  return(final_output)
}
