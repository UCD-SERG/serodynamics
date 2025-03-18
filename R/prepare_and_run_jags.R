#' @title Prepare Dataset and Run JAGS Model
#' @author Kwan Ho Lee
#' @description
#' Reads the dataset, extracts required subjects, and runs the JAGS model.
#'
#' @param file_path Path to the dataset file. If `NULL`, automatically searches for the correct path.
#' @param file_mod Path to the JAGS model file (default is set automatically).
#' @param strat A character string specifying the stratification variable (default: `"bldculres"`).
#' @param id The subject ID to filter the dataset (default: `NULL`).
#' @param antigen_iso The antigen identifier to filter the dataset (default: `NULL`).
#' @return A [list] containing:
#' - `dat`: The extracted dataset for the selected subject and antigen.
#' - `dataset`: The full processed dataset.
#' - `nepal_sees_jags_post`: The JAGS model output for the selected subject and antigen.
#' - `nepal_sees_jags_post2`: The JAGS model output for the entire dataset.
#' @export
#' @example inst/examples/examples-prepare_and_run_jags.R

prepare_and_run_jags <- function(file_path = NULL,
                                 file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
                                 strat = "bldculres",
                                 id = NULL,
                                 antigen_iso = NULL) {
  
  # Step 1: Locate Dataset File Automatically
  if (is.null(file_path)) {
    file_path <- system.file("extdata", "SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv", package = "serodynamics")
    
    # If running in development mode, use the `inst/` path
    if (file_path == "" || !file.exists(file_path)) {
      file_path <- "inst/extdata/SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv"
    }
  }
  
  # Step 2: Check if file exists
  if (!file.exists(file_path)) {
    stop("Error: Dataset file not found. Ensure it is in 'inst/extdata/'.")
  }
  
  # Step 3: Read dataset using readr::read_csv
  nepal_sees <- readr::read_csv(file_path)
  
  # Convert to case data format (assuming as_case_data() is defined in our package)
  dataset <- nepal_sees |>
    as_case_data(id_var = "person_id",
                 biomarker_var = "antigen_iso",
                 value_var = "result",
                 time_in_days = "dayssincefeveronset")
  
  # Step 4: Extract specific subject and antigen data using dplyr::filter
  dat <- dplyr::filter(dataset, id == !!id, antigen_iso == !!antigen_iso)
  
  # Check if the dataset has at least 5 observations
  if (nrow(dat) < 5) {
    warning("Warning: The selected subject-antigen pair has fewer than 5 observations. The JAGS model may not run correctly.")
  }
  
  # Step 5: Run JAGS model for the specific subject and antigen
  nepal_sees_jags_post <- run_mod(
    data = dat, 
    file_mod = file_mod,  
    nchain = 2,
    nadapt = 100,
    nburn = 100,
    nmc = 500,
    niter = 1000,
    strat = strat
  )
  
  # Step 6: Run JAGS model for the entire dataset
  nepal_sees_jags_post2 <- run_mod(
    data = dataset,
    file_mod = file_mod,  
    nchain = 2,
    nadapt = 100,
    nburn = 100,
    nmc = 500,
    niter = 1000,
    strat = strat
  )
  
  return(list(dat = dat, 
              dataset = dataset,
              nepal_sees_jags_post = nepal_sees_jags_post, 
              nepal_sees_jags_post2 = nepal_sees_jags_post2))
}
