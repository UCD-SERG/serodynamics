get_timeindays_var <- function(object) {
  
  var <- object |> attr("timeindays")
  if (is.null(var)) var <- "timeindays"
  return(var)
  
}

get_timeindays <- function(object) {
  
  var <- object |> get_timeindays_var()
  
  return(object[[var]])
  
}