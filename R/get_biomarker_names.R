get_biomarker_names <- function(data) {
  biomarker_names_var <- data |> get_biomarker_names_var()
  
  biomarker_names <- data[[biomarker_names_var]]
  
  return(biomarker_names)
}

get_biomarker_names_var <- function(data) {
  biomarker_names_var <-
    data |> attr("biomarker_var")
  
  if (is.null(biomarker_names_var)) {
    biomarker_names_var <- "antigen_iso"
  }
  
  return(biomarker_names_var)
}
