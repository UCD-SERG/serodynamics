#' @title Prepare Dataset and Run JAGS Model
#' @author Kwan Ho Lee
#' @description
#' Reads the dataset, extracts required subjects, and runs the JAGS model.
#'
#' @param file_path Path to the dataset file. If `NULL`, automatically searches for the correct path.
#' @param file_mod Path to the JAGS model file (default is set automatically).
#' @param strat A character string specifying the stratification variable (default: `"bldculres"`).
#' @return A [list] containing:
#' - `dat`: The extracted dataset for the selected subject.
#' - `jags_post`: The JAGS model output.
#' @export
#' @example inst/examples/examples-prepare_and_run_jags.R

prepare_and_run_jags <- function(file_path = NULL,
                                 file_mod = fs::path_package("serodynamics", "extdata/model.jags"),
                                 strat = "bldculres") {
  
  library(dplyr)
  library(readr)
  library(fs)  # Ensure `fs` is loaded
  
  # 🔹 Step 1: Locate Dataset File Automatically
  if (is.null(file_path)) {
    file_path <- system.file("extdata", "SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv", package = "serodynamics")
    
    # If running in development mode, use the `inst/` path
    if (file_path == "" || !file.exists(file_path)) {
      file_path <- "inst/extdata/SEES_Case_Nepal_ForSeroKinetics_02-13-2025.csv"
    }
  }
  
  # 🔹 Step 2: Check if file exists
  if (!file.exists(file_path)) {
    stop("Error: Dataset file not found. Ensure it is in 'inst/extdata/'.")
  }
  
  # 🔹 Step 3: Read dataset
  nepal_sees <- read_csv(file_path)
  
  # Convert to case data format
  dataset <- nepal_sees |>
    as_case_data(id_var = "person_id",
                 biomarker_var = "antigen_iso",
                 value_var = "result",
                 time_in_days = "dayssincefeveronset")
  
  # 🔹 Step 4: Extract subjects with visit_num = 5
  subset_data <- dataset %>% filter(visit_num == 5)
  id_antigen_pairs <- subset_data %>% select(id, antigen_iso) %>% distinct()
  
  # 🔹 Step 5: Filter for subjects with at least 5 visits
  filtered_dataset <- dataset %>%
    semi_join(id_antigen_pairs, by = c("id", "antigen_iso")) %>%
    filter(visit_num >= 1 & visit_num <= 5)
  
  # 🔹 Step 6: Extract a single subject (e.g., sees_npl_128)
  dat <- filtered_dataset %>%
    filter(id == "sees_npl_128")
  
  # 🔹 Step 7: Run JAGS model
  jags_post <- run_mod(
    data = dat, 
    file_mod = file_mod,  # Now automatically assigned
    nchain = 2,
    nadapt = 100,
    nburn = 100,
    nmc = 500,
    niter = 1000,
    strat = strat
  )
  
  return(list(dat = dat, jags_post = jags_post))  # Return both dataset and model output
}
