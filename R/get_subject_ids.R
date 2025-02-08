get_subject_ids <- function(data) {
  subject_id_varname <- data |> get_subject_id_var()

  subject_ids <- data[[subject_id_varname]]

  return(subject_ids)
}

get_subject_id_var <- function(data) {
  subject_id_varname <-
    data |> attr("subject_id")

  if (is.null(subject_id_varname)) {
    subject_id_varname <- "index_id"
  }

  return(subject_id_varname)
}
