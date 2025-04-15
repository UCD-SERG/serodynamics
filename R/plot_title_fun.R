#' Plotting title for diagnostic functions

plot_title_fun <- function(i, j) {
  subtitle <-  ifelse(j == "None", 
                      paste0("ag/iso = ", j),
                      paste0("ag/iso = ", 
                             j, "; strata =  ", i))
  return(subtitle)
}
