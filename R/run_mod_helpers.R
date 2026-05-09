#' Setup stratification list
#'
#' @param data Input data frame
#' @param strat Stratification variable name (or NA)
#'
#' @returns A vector of stratification levels (type preserved from input column)
#' @keywords internal
#' @noRd
setup_stratification <- function(data, strat) {
  if (is.na(strat)) {
    "None"
  } else {
    # Validate that strat is a column name
    if (!strat %in% names(data)) {
      cli::cli_abort(
        c(
          "Stratification variable {.var {strat}} not found in data.",
          "i" = "Available columns: {.val {names(data)}}"
        )
      )
    }
    # Get unique levels, excluding NA
    levels <- unique(data[[strat]])
    levels <- levels[!is.na(levels)]
    # Return as-is to preserve type for filtering
    levels
  }
}

#' Create output shell for MCMC results
#'
#' @returns A data frame with the standard output structure
#' @keywords internal
#' @noRd
create_output_shell <- function() {
  data.frame(
    "Iteration" = NA,
    "Chain" = NA,
    "Parameter" = NA,
    "value" = NA,
    "Parameter_sub" = NA,
    "Subject" = NA,
    "Iso_type" = NA,
    "Stratification" = NA
  )
}

#' Filter data by stratification level
#'
#' @param data Input data frame
#' @param strat Stratification variable name (or NA)
#' @param strat_level Current stratification level
#'
#' @returns Filtered data frame
#' @keywords internal
#' @noRd
filter_by_stratification <- function(data, strat, strat_level) {
  if (is.na(strat)) {
    data
  } else {
    # Handle NA strat_level explicitly
    if (is.na(strat_level)) {
      data |>
        dplyr::filter(is.na(.data[[strat]]))
    } else {
      data |>
        dplyr::filter(.data[[strat]] == strat_level)
    }
  }
}

#' Process MCMC output to add antigen-iso and subject information
#'
#' @param mcmc_unpack Unpacked MCMC output from ggmcmc::ggs()
#' @param longdata Prepared data with attributes
#' @param strat_level Current stratification level
#'
#' @returns Processed data frame with antigen-iso and subject info
#' @keywords internal
#' @noRd
process_mcmc_output <- function(mcmc_unpack, longdata, strat_level) {
  # Extract antigen-iso combinations
  iso_dat <- data.frame(attributes(longdata)$antigens)
  iso_dat <- iso_dat |>
    dplyr::mutate(Subnum = as.numeric(row.names(iso_dat)))
  
  # Parse parameter names to extract subject and parameter info
  mcmc_unpack <- mcmc_unpack |>
    dplyr::mutate(
      Subnum = sub(".*,", "", .data$Parameter),
      Parameter_sub = sub("\\[.*", "", .data$Parameter),
      Subject = sub("\\,.*", "", .data$Parameter)
    ) |>
    dplyr::mutate(
      Subnum = as.numeric(sub("\\].*", "", .data$Subnum)),
      Subject = sub(".*\\[", "", .data$Subject)
    )
  
  # Merge antigen-iso information
  mcmc_unpack <- dplyr::left_join(mcmc_unpack, iso_dat, by = "Subnum")
  
  # Merge subject IDs
  ids <- data.frame(attr(longdata, "ids")) |>
    dplyr::mutate(Subject = as.character(dplyr::row_number()))
  mcmc_unpack <- dplyr::left_join(mcmc_unpack, ids, by = "Subject")
  
  # Clean up and rename columns
  mcmc_final <- mcmc_unpack |>
    dplyr::select(!c("Subnum", "Subject")) |>
    dplyr::rename(
      c("Iso_type" = "attributes.longdata..antigens",
        "Subject" = "attr.longdata...ids..")
    )
  
  # Add stratification label
  mcmc_final$Stratification <- strat_level
  
  mcmc_final
}

#' Format final model output
#'
#' @param model_out Raw model output data frame
#' @param mod_atts Model attributes from ggmcmc
#' @param priorspec Prior specifications
#' @param fit_res Fitted values and residuals
#' @param post_fit Optional raw posterior fit object
#' @param with_post Whether to include raw posterior
#' @param post_attr_name Name for posterior attribute
#'   ("jags.post" or "stan.fit")
#'
#' @returns Formatted sr_model object
#' @keywords internal
#' @noRd
format_model_output <- function(model_out,
                                mod_atts,
                                priorspec,
                                fit_res,
                                post_fit = NULL,
                                with_post = FALSE,
                                post_attr_name = "jags.post") {
  # Convert to tibble and reorder columns
  model_out <- tibble::as_tibble(model_out)
  
  model_out <- model_out[, c("Iteration", "Chain", "Parameter", "Iso_type",
                             "Stratification", "Subject", "value")]
  
  # Add attributes
  current_atts <- attributes(model_out)
  current_atts <- c(current_atts, mod_atts)
  attributes(model_out) <- current_atts
  
  # Add priors
  model_out <- model_out |>
    structure("priors" = attributes(priorspec)$used_priors)
  
  # Add fitted and residuals
  model_out <- model_out |>
    structure(fitted_residuals = fit_res)
  
  # Conditionally add raw posterior
  if (with_post && !is.null(post_fit)) {
    attr(model_out, post_attr_name) <- post_fit
  }
  
  # Add sr_model class
  model_out <- model_out |>
    structure(class = union("sr_model", class(model_out)))
  
  model_out
}
