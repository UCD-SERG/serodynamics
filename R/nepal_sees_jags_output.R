#'
#'
#' SEES Typhoid run_mod jags output
#'
#' A [serodynamics::run_mod()] output 
#' using the [nepal_sees] example data set as input
#' and stratifying by column `"bldculres"`, 
#' which is the diagnosis type (typhoid or
#' paratyphoid). Keeping only the newperson, sees_npl_1, sees_npl_2.
#'
#' @format ## `nepal_sees_jags_output`
#' A [list] consisting of the following named elements:
#' \describe{
#'  \item{curve_params}{A [data.frame] titled `curve_params` that contains the
#'   posterior distribution for the predictive distribution (newperson) and 
#'   two modeled subject (sees_npl_1, sees_npl_2)}
#'  \item{attributes}{A [list] of `attributes` that summarize the jags inputs}
#' }
#' @source reference study: <https://doi.org/10.1016/S2666-5247(22)00114-8>
"nepal_sees_jags_output"
