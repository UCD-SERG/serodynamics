get_subject_ids <- function(data) {
  
  subject_id_varname <- 
    data |> attr("subject_id")
  
  if (is.null(subject_id_varname)) {
    subject_id_varname <- "index_id"
  }
    
  subject_ids <- unique(data[[subject_id_varname]])
  
  return(subject_ids)
  
}