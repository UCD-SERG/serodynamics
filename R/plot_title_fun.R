#' Plotting title for diagnostic functions
#' 
#' @param i input strata 
#' @param j input antigen/iso combination

plot_title_fun <- function(i, j) {
  subtitle <-  ifelse(j == "None", 
                      paste0("ag/iso = ", j),
                      paste0("ag/iso = ", 
                             j, "; strata =  ", i))
  return(subtitle)
}
