#' @title Unpacking MCMC Object
#' @author Sam Schildhauer
#' @description
#'  `unpack_jags()` takes an MCMC output from run_mod and unpacks it correctly
#'  for all population parameters.
#' @param data A [dplyr::tbl_df()] output object from run_mod with mcmc syntax.
#' @returns A [dplyr::tbl_df()] that
#' contains MCMC samples from the joint posterior distribution of the model 
#' with unpacked parameters, isotypes, and subjects.
#' @keywords internal
unpack_jags <- function(data) {

  param_recode <- function(x) {
    dplyr::recode(x, "1" = "y0", "2" = "y1", "3" = "t1", "4" = "alpha", 
                  "5" = "shape")
  }
  # Unpacking mu.par
  #Separating population parameters from the rest of the data
  regex <- "([[:alnum:].]+)\\[([0-9]+),([0-9]+)\\]" # For unpacking
  jags_mupar <- data |>
    dplyr::filter(grepl("mu.par", .data$Parameter)) |>
    dplyr::mutate(
      Subject = gsub(regex, "\\1", .data$Parameter),
      Subnum = gsub(regex, "\\2", .data$Parameter),
      Param = param_recode(gsub(regex, "\\3", .data$Parameter))
    )
  # Unpacking prec.par
  regex2 <- "([[:alnum:].]+)\\[([0-9]+),([0-9]+),([0-9]+)\\]" # For unpacking
  jags_precpar <- data |>
    dplyr::filter(grepl("prec.par", .data$Parameter)) |>
    dplyr::mutate(
      Subject = gsub(regex2, "\\1", .data$Parameter),
      Subnum = gsub(regex2, "\\2", .data$Parameter),
      Param = paste0(param_recode(gsub(regex2, "\\3", .data$Parameter)), ", ",
                     param_recode(gsub(regex2, "\\4", .data$Parameter)))
    ) 
    
  # Unpacking preclogy
  regex3 <- "([[:alnum:].]+)\\[([0-9]+)\\]" # For unpacking
  jags_preclogy <- data |>
    dplyr::filter(grepl("prec.logy", .data$Parameter)) |>
    dplyr::mutate(
      Subject = gsub(regex3, "\\1", .data$Parameter),
      Subnum = gsub(regex3, "\\2", .data$Parameter),
      Param = NA,
    )

  # Working with jags unpacked ggs outputs to clarify parameter and subject
  jags_unpack_params <- data |>
    dplyr::mutate(
      Subject = gsub(regex, "\\2", .data$Parameter),
      Subnum = gsub(regex, "\\3", .data$Parameter),
      Param = param_recode(gsub(regex, "\\1", .data$Parameter))
    ) |> 
    dplyr::filter(.data$Param %in% c("y0", "y1", "t1", "alpha", "shape"))

  # Putting data frame together
  jags_unpack_bind <- rbind(jags_unpack_params, jags_mupar, jags_precpar,
                            jags_preclogy)

  return(jags_unpack_bind)
}
