library(dplyr)
library(tidyr)

prep_data <- function(dataframe) {
  # Ensure the data has the required columns
  if (!("antigen_iso" %in% names(dataframe)) || !("visit_num" %in% names(dataframe))) {
    stop("Dataframe must contain 'antigen_iso' and 'visit_num' columns")
  }
  
  # Modified (Tidyverse version): Extract unique visits, antigens, and subjects
  visits <- dataframe %>% pull(visit_num) %>% unique()
  antigens <- dataframe %>% pull(antigen_iso) %>% unique()
  subjects <- dataframe %>% pull(index_id) %>% unique()
  
  # Initialize arrays to store the formatted data
  max_visits <- length(visits)
  max_antigens <- length(antigens)
  num_subjects <- length(subjects)
  
  # Define arrays with dimensions to accommodate extra dummy subject
  dimnames1 <- list(
    subjects = c(subjects, "newperson"),
    visit_number = paste0("V", visits)
  )
  
  dims1 <- sapply(F = length, X = dimnames1)
  
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
  
  nsmpl <- integer(num_subjects + 1)  # Array to store the maximum number of samples per participant
  
  # Using Tidyverse for data filtering and mutation
  for (i in seq_len(num_subjects)) {
    # Modified (Tidyverse version):
    subject_data <- dataframe %>% 
      filter(index_id == subjects[i]) %>%
      group_by(visit_num, antigen_iso) %>%
      mutate(result = log(pmax(0.01, result)))  # Modified (Tidyverse): Log-transform and handle zeroes
    
    subject_visits <- subject_data %>% pull(visit_num) %>% unique()
    nsmpl[i] <- length(subject_visits)  # Number of non-missing visits for this participant
    
    for (j in seq_along(subject_visits)) {
      for (k in seq_len(max_antigens)) {
        # Modified (Tidyverse version)
        subset <- subject_data %>%
          filter(visit_num == subject_visits[j], antigen_iso == antigens[k])
        
        if (nrow(subset) > 0) {
          visit_times[i, j] <- subset$timeindays[1]  # Assuming timeindays is the same for all rows
          antibody_levels[i, j, k] <- subset$result[1]
        }
      }
    }
  }
  
  # Add missing observation for Bayesian inference
  visit_times[num_subjects + 1, 1:3] <- c(5, 30, 90)
  antibody_levels[num_subjects + 1, 1:3, ] <- NA
  nsmpl[num_subjects + 1] <- 3  # Since we manually add three timepoints for the dummy subject
  
  # Return results as a list
  to_return <- list(
    "smpl.t" = visit_times, 
    "logy" = antibody_levels, 
    "n_antigen_isos" = max_antigens, 
    "nsmpl" = nsmpl, 
    "nsubj" = num_subjects + 1
  ) %>%
    structure(
      antigens = antigens,
      n_antigens = max_antigens,
      ids = c(subjects, "newperson")
    )
  
  return(to_return)
}
