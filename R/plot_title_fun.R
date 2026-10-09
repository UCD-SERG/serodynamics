#' Plotting title for diagnostic functions
#' 
#' @param i input strata 
#' @param j input antigen/iso combination
#' @param h input subject
#' @keywords internal

plot_title_fun <- function(i, j, h) {
  subtitle <-  ifelse(j == "None", 
                      paste0("ag/iso = ", j),
                      paste0("ag/iso = ", 
                             j, "; strata =  ", i,
                             ", sub = ", h))
  return(subtitle)
}
