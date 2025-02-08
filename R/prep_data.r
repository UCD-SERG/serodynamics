#' prepare data for JAGs
#'
#' @param dataframe a [data.frame] containing ...
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
prep_data <- function(dataframe) {
  # Ensure the data has the required columns
  columns_missing <-
    !("antigen_iso" %in% names(dataframe)) ||
    !("visit_num" %in% names(dataframe))

  if (columns_missing) {
    stop("Dataframe must contain 'antigen_iso' and 'visit_num' columns")
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
    get_subject_ids() |>
    unique()

  # Initialize arrays to store the formatted data
  max_visits <- length(visits)
  max_antigens <- length(antigens)
  num_subjects <- length(subjects)

  # Define arrays with dimensions to accommodate extra dummy subject

  dimnames1 <- list(
    subjects = c(subjects, "newperson"),
    visit_number = paste0("V", visits)
  )

  dims1 <- sapply(FUN = length, X = dimnames1)

  visit_times <- array(
    NA,
    dim = dims1,
    dimnames = dimnames1
  )

  dimnames2 <- list(
    subjects = c(subjects, "newperson"),
    visit_number = paste0("V", visits),
    antigens = antigens
  )

  antibody_levels <- array(
    NA,
    dim = c(num_subjects + 1, max_visits, max_antigens),
    dimnames = dimnames2
  )

  # Array to store the maximum number of samples per participant
  nsmpl <- integer(num_subjects + 1)

  for (i in seq_len(num_subjects)) {
    subject_data <- dataframe[dataframe$index_id == subjects[i], ]
    subject_visits <- sort(unique(subject_data$visit_num))

    # Number of non-missing visits for this participant
    nsmpl[i] <- length(subject_visits)

    for (j in seq_along(subject_visits)) {
      for (k in seq_len(max_antigens)) {
        index <- subject_data$visit_num == subject_visits[j] &
          subject_data$antigen_iso == antigens[k]
        subset <- subject_data[index, ]
        if (nrow(subset) > 0) {
          if (length(subset |> get_timeindays()) != 1) {
            cli::cli_abort(
              c(
                "Error at subject: {subjects[i]}, ",
                "visit: {subject_visits[j]},",
                "antigen: {antigens[k]}",
                "- # of items in {.var {get_timeindays_var(subset)}} != 1."
              )
            )
          }
          visit_times[i, j] <- subset |> get_timeindays()
          antibody_levels[i, j, k] <- log(max(
            0.01,
            subset |>
              serocalculator:::get_value()
          ))
          # Log-transform and handle zeroes
        }
      }
    }
  }

  # Add missing observation for Bayesian inference
  visit_times[num_subjects + 1, 1:3] <- c(5, 30, 90)
  # Ensure corresponding antibody levels are set to NA (explicitly missing)
  antibody_levels[num_subjects + 1, 1:3, ] <- NA
  nsmpl[num_subjects + 1] <- 3
  # Since we manually add three time-points for the dummy subject




  # Return results as a list
  to_return <-
    list(
      "smpl.t" = visit_times,
      "logy" = antibody_levels,
      "n_antigen_isos" = max_antigens,
      "nsmpl" = nsmpl,
      "nsubj" = num_subjects + 1
    ) |>
    structure(
      class = c("prepped_jags_data", "list"),
      antigens = antigens,
      n_antigens = max_antigens,
      ids = c(subjects, "newperson")
    )

  # Return results as a list
  return(to_return)
}
