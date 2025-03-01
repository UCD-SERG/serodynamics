#'
#'
#' SEES Typhoid run_mod jags output
#'
#' An [serodynamics::run_mod()] output using sees_nepal data as input, 
#' stratifying by bldculres, which is the diagnosis type (typhoid or
#' paratyphoid).
#'
#' @format ## `nepal_sees_jags_post`
#' A [list] consisting of the following named elements:
#' \describe{
#'  \item{curve_params}{A [data.frame] titled `curve_params` that contains the
#'   posterior distribution}
#'  \item{jags.post}{An [list] of [runjags::runjags-class] objects}
#'  \item{attributes}{A [list] of `attributes` that summarize the jags inputs}
#' }
#' @source reference study: <https://doi.org/10.1016/S2666-5247(22)00114-8>
"nepal_sees_jags_post"
