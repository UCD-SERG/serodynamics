#' prepare data for JAGs
#'
#' @param dataframe a [data.frame] containing ...
#' @param biomarker_column
#' [character] string indicating
#' which column contains antigen-isotype names
#' @param verbose whether to produce verbose messaging
#' @param add_newperson whether to add an extra record with missing data
#'
#' @returns a `prepped_jags_data` object (a [list] with extra attributes ...)
#' @export
#'
#' @examples
#' set.seed(1)
#' raw_data <-
#'   serocalculator::typhoid_curves_nostrat_100 |>
#'   sim_case_data(n = 5)
#' prepped_data <- prep_data(raw_data)
prep_data <- function(
    dataframe,
    biomarker_column = get_biomarker_names_var(dataframe),
    verbose = FALSE,
    add_newperson = TRUE) {
  # Ensure the data has the required columns
  columns_missing <-
    !("antigen_iso" %in% names(dataframe)) |
    !("visit_num" %in% names(dataframe))
  
  if (columns_missing) {
    cli::cli_abort(
      message =
        "{.arg dataframe} must contain 'antigen_iso' and 'visit_num' columns"
    )
  }
  # Extract unique visits and antigens
  visits <-
    dataframe$visit_num |>
    as.numeric() |>
    unique() |>
    sort()
  
  antigens <-
    dataframe$antigen_iso |>
    unique()
  
  subjects <-
    dataframe |>
    serocalculator::ids() |>
    unique()
  
  # Initialize arrays to store the formatted data
  max_visits <- length(visits)
  n_antigens <- length(antigens)
  num_subjects <- length(subjects)
  
  # Define arrays with dimensions to accommodate extra dummy subject
  
  if (add_newperson) {
    subjects1 <- c(subjects, "newperson")
  } else {
    subjects1 <- subjects
  }
  
  dimnames1 <- list(
    subjects = subjects1,
    visit_number = paste0("V", visits)
  )
  
  dims1 <- sapply(FUN = length, X = dimnames1) # nolint: undesirable_function_linter
  
  visit_times <- array(
    NA,
    dim = dims1,
    dimnames = dimnames1
  )
  
  dimnames2 <- list(
    subjects = subjects1,
    visit_number = paste0("V", visits),
    antigens = antigens
  )
  
  antibody_levels <- array(
    NA,
    dim = c(length(subjects1), max_visits, n_antigens),
    dimnames = dimnames2
  )
  
  # Array to store the maximum number of samples per participant:
  nsmpl <- integer(length(subjects1)) |>
    purrr::set_names(subjects1)
  
  ids_varname <- serocalculator::ids_varname(dataframe)
  
  for (cur_subject in subjects) {
    subject_data <-
      dataframe |>
      dplyr::filter(.data[[ids_varname]] == cur_subject)
    subject_visits <- unique(subject_data$visit_num)
    # Number of non-missing visits for this participant:
    nsmpl[cur_subject] <- length(subject_visits)
    
    
    for (cur_visit in subject_visits) {
      for (cur_antigen in antigens) {
        subset <-
          subject_data |>
          filter(
            .data$visit_num == cur_visit,
            .data$antigen_iso == cur_antigen
          )
        
        if (nrow(subset) == 1) {
          visit_times[cur_subject, cur_visit] <-
            subset |> get_timeindays()
          # Log-transform and handle zeroes:
          antibody_levels[cur_subject, cur_visit, cur_antigen] <-
            subset |>
            serocalculator::get_values() |>
            max(0.01) |>
            log()
        } else if (nrow(subset) > 1) {
          cli::cli_abort(
            c(
              "Multiple records for ",
              "subject: {cur_subject}, ",
              "visit: {cur_visit}, ",
              "antigen: {cur_antigen}"
            )
          )
        } else {
          if (verbose) {
            cli::cli_inform(
              c(
                "No observations for ",
                "subject: {cur_subject}, ",
                "visit: {cur_visit}, ",
                "antigen: {cur_antigen}."
              )
            )
          }
        }
      }
    }
  }
  
  
  if (add_newperson) {
    # Add missing observation for Bayesian inference
    visit_times[num_subjects + 1, 1:3] <- c(5, 30, 90)
    # Ensure corresponding antibody levels are set to NA (explicitly missing)
    antibody_levels[num_subjects + 1, 1:3, ] <- NA
    # Since we manually add three timepoints for the dummy subject:
    nsmpl["newperson"] <- 3
  }
  
  to_return <-
    list(
      "smpl.t" = visit_times,
      "logy" = antibody_levels,
      "n_antigen_isos" = n_antigens,
      "nsmpl" = nsmpl,
      "nsubj" = length(subjects1)
    ) |>
    structure(
      class = c("prepped_jags_data", "list"),
      antigens = antigens,
      n_antigens = n_antigens,
      ids = subjects1
    )
  
  # Return results as a list
  return(to_return)
}
