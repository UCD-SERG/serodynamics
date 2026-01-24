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

  unpack_with_pattern <- function(data, filter_pattern, regex_pattern,
                                  subject_repl, subnum_repl, param_fun) {
    data |>
      dplyr::filter(grepl(filter_pattern, .data$Parameter)) |>
      dplyr::mutate(
        Subject = gsub(regex_pattern, subject_repl, .data$Parameter),
        Subnum = gsub(regex_pattern, subnum_repl, .data$Parameter),
        Param = param_fun(.data$Parameter, regex_pattern)
      )
  }

  # Regular expressions for unpacking
  regex_2idx <- "([[:alnum:].]+)\\[([0-9]+),([0-9]+)\\]"          # e.g. x[1,2]
  regex_3idx <- "([[:alnum:].]+)\\[([0-9]+),([0-9]+),([0-9]+)\\]"  # e.g. x[1,2,3]
  regex_1idx <- "([[:alnum:].]+)\\[([0-9]+)\\]"                    # e.g. x[1]

  # Unpacking mu.par
  # Separating population parameters from the rest of the data
  jags_mupar <- unpack_with_pattern(
    data = data,
    filter_pattern = "mu.par",
    regex_pattern = regex_2idx,
    subject_repl = "\\1",
    subnum_repl = "\\2",
    param_fun = function(param, pattern) {
      param_recode(gsub(pattern, "\\3", param))
    }
  )

  # Unpacking prec.par
  jags_precpar <- unpack_with_pattern(
    data = data,
    filter_pattern = "prec.par",
    regex_pattern = regex_3idx,
    subject_repl = "\\1",
    subnum_repl = "\\2",
    param_fun = function(param, pattern) {
      paste0(
        param_recode(gsub(pattern, "\\3", param)), ", ",
        param_recode(gsub(pattern, "\\4", param))
      )
    }
  )

  # Unpacking prec.logy
  jags_preclogy <- unpack_with_pattern(
    data = data,
    filter_pattern = "prec.logy",
    regex_pattern = regex_1idx,
    subject_repl = "\\1",
    subnum_repl = "\\2",
    param_fun = function(param, pattern) {
      paste0(
        param_recode(gsub(pattern, "\\3", param)), ", ",
        param_recode(gsub(pattern, "\\4", param))
  )
    }
  )

  # Working with jags unpacked ggs outputs to clarify parameter and subject
  jags_unpack_params <- data |>
    dplyr::mutate(
      Subject = gsub(regex_2idx, "\\2", .data$Parameter),
      Subnum = gsub(regex_2idx, "\\3", .data$Parameter),
      Param = param_recode(gsub(regex_2idx, "\\1", .data$Parameter))
    ) |> 
    dplyr::filter(.data$Param %in% c("y0", "y1", "t1", "alpha", "shape"))

  # Putting data frame together
  jags_unpack_bind <- dplyr::bind_rows(
    jags_unpack_params,
    jags_mupar,
    jags_precpar,
    jags_preclogy
  )

  return(jags_unpack_bind)
}
