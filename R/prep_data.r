


prep_data <- function(dataframe) {
  # Ensure the data has the required columns
  if (!("antigen_iso" %in% names(dataframe)) || !("visit" %in% names(dataframe))) {
    stop("Dataframe must contain 'antigen_iso' and 'visit' columns")
  }
  

  
  # Extract unique visits and antigens
  visits <- unique(dataframe$visit)
  antigens <- unique(dataframe$antigen_iso)
  subjects <- unique(dataframe$index_id)
  
  # Initialize arrays to store the formatted data
  max_visits <- length(visits)
  max_antigens <- length(antigens)
  num_subjects <- length(subjects)

  # Define arrays with dimensions to accommodate extra dummy subject
  visit_times <- array(NA, dim = c(num_subjects + 1, max_visits))
  antibody_levels <- array(NA, dim = c(num_subjects + 1, max_visits, max_antigens))
  nsmpl <- integer(num_subjects + 1)  # Array to store the maximum number of samples per participant
  
  # Populate the arrays
  # for (i in seq_len(num_subjects)) {
  #   for (j in seq_len(max_visits)) {
  #     for (k in seq_len(max_antigens)) {
  #       subset <- dataframe[dataframe$index_id == subjects[i] & dataframe$visit == visits[j] & dataframe$antigen_iso == antigens[k], ]
  #       if (nrow(subset) > 0) {
  #         visit_times[i, j] <- subset$TimeInDays
  #         antibody_levels[i, j, k] <- log(max(0.01, subset$result))  # Log-transform and handle zeroes
  #       }
  #     }
  #   }
  # }
  for (i in seq_len(num_subjects)) {
    subject_data <- dataframe[dataframe$index_id == subjects[i], ]
    subject_visits <- unique(subject_data$visit)
    nsmpl[i] <- length(subject_visits)  # Number of non-missing visits for this participant
    
    for (j in seq_along(subject_visits)) {
      for (k in seq_len(max_antigens)) {
        subset <- subject_data[subject_data$visit == subject_visits[j] & subject_data$antigen_iso == antigens[k], ]
        if (nrow(subset) > 0) {
          visit_times[i, j] <- subset$TimeInDays
          antibody_levels[i, j, k] <- log(max(0.01, subset$result))  # Log-transform and handle zeroes
        }
      }
    }
  }
  
  # Add missing observation for Bayesian inference
  visit_times[num_subjects + 1, 1:3] <- c(5, 30, 90)
  # Ensure corresponding antibody levels are set to NA (explicitly missing)
  antibody_levels[num_subjects + 1, 1:3, ] <- NA
  nsmpl[num_subjects + 1] <- 3  # Since we manually add three timepoints for the dummy subject
  
  # Model parameters
  ndim <- 5  # Assuming 5 model parameters [ y0, y1, t1, alpha, shape]
  mu.hyp   <- array(NA, dim = c(max_antigens, ndim))
  prec.hyp <- array(NA, dim = c(max_antigens, ndim, ndim))
  omega    <- array(NA, dim = c(max_antigens, ndim, ndim))
  wishdf   <- rep(NA, max_antigens)
  prec.logy.hyp <- array(NA, dim = c(max_antigens, 2))
  
  # Fill parameter arrays
  # log(c(y0,  y1,    t1,  alpha, shape-1))
  for (k.test in 1:max_antigens) {
    mu.hyp[k.test,] <-        c(1.0, 7.0, 1.0, -4.0, -1.0)
    prec.hyp[k.test,,] <- diag(c(1.0, 0.00001, 1.0, 0.001, 1.0))
    omega[k.test,,] <-    diag(c(1.0, 50.0, 1.0, 10.0, 1.0))
    wishdf[k.test] <- 20
    prec.logy.hyp[k.test,] <- c(4.0, 1.0)
  }
  
  
  
  # Return results as a list
  return(list(
    "smpl.t" = visit_times, 
    "logy" = antibody_levels, 
    "ntest" = max_antigens, 
    "nsmpl" = nsmpl, 
    "nsubj" = num_subjects + 1,
    "ndim" = ndim,
    "mu.hyp" = mu.hyp, 
    "prec.hyp" = prec.hyp,
    "omega" = omega, 
    "wishdf" = wishdf,
    "prec.logy.hyp" = prec.logy.hyp
  ))
}

