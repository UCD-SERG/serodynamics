#'
#'
#' SEES Typhoid run_mod jags output
#'
#' An [serodynamics::run_mod()] output using sees_nepal data as input, stratifying
#' by bldculres, which is the diagnosis type (typhoid or paratyphoid).
#'
#' @format ## `nepal_sees_jags_post`
#' A jags.post [list] object or multiple jags.post [list]
#' if stratified. Returned as a [list] of class [runjags::runjags-class]
#' \describe{
#'  \item{curve_params}{A [data.frame] titled `curve_params` that contains the
#'   posterior distribution will be exported with the following attributes:
#'  - `iteration` = number of sampling iterations.
#'  - `chain` = number of mcmc chains run; between 1 and 4.
#'  - `indexid` = "newperson", indicating posterior distribution.
#'  - `antigen_iso` = antibody/antigen type combination being evaluated
#'  - `alpha` = posterior estimate of decay rate
#'  - `r` = posterior estimate of shape parameter
#'  - `t1` = posterior estimate of time to peak
#'  - `y0` = posterior estimate of baseline antibody concentration
#'  - `y1` = posterior estimate of peak antibody concentration
#'  - `stratified variable` = the variable that jags was stratified by
#'  }
#'  \item{jags.post}{An object with class [runjags::runjags]}
#'  \item{attributes}{A [list] of `attributes` that summarize the jags inputs,
#'  including:
#'  - `class`: Class of the output object.
#'  - `nChain`: Number of chains run.
#'  - `nParameters`: The amount of parameters estimated in the model.
#'  - `nIterations`: Number of iteration specified.
#'  - `nBurnin`: Number of burn ins.
#'  - `nThin`: Thinning number (niter/nmc)
#'  }
#'  }
#' @source reference study: <https://doi.org/10.1016/S2666-5247(22)00114-8>
"nepal_sees_jags_post"
