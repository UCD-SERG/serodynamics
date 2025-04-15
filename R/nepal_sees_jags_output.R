#'
#'
#' SEES Typhoid run_mod jags output
#'
#' A [serodynamics::run_mod()] output 
#' using the [nepal_sees] example data set as input
#' and stratifying by column `"bldculres"`, 
#' which is the diagnosis type (typhoid or
#' paratyphoid). Keeping only IDs "newperson", "sees_npl_1", "sees_npl_2".
#'
#' @format ## `nepal_sees_jags_output`
#' A [list] consisting of the following named elements:
#' \describe{
#'  \item{curve_params}{A [data.frame] titled `curve_params` that contains the
#'   posterior predictive distribution of the person-specific parameters for a
#'   "new person" with no observed data (`Subject = "newperson"`) and posterior
#'   distributions of the person-specific parameters for two arbitrarily-chosen
#'   subjects (`"sees_npl_1"` and`"sees_npl_2"`)}}
#'  \item{attributes}{A [list] of `attributes` that summarize the jags inputs}
#' }
#' @source reference study: <https://doi.org/10.1016/S2666-5247(22)00114-8>
"nepal_sees_jags_output"
