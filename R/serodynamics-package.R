#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom dplyr .data
#' @importFrom dplyr all_of
#' @importFrom dplyr filter
#' @importFrom dplyr mutate
#' @importFrom dplyr n
#' @importFrom dplyr reframe
#' @importFrom dplyr rename
#' @importFrom dplyr rowwise
#' @importFrom dplyr select
#' @importFrom dplyr ungroup
#' @importFrom ggmcmc ggs
#' @importFrom ggplot2 theme_bw
#' @importFrom ggplot2 vars
#' @importFrom rlang .data
#' @importFrom rlang .env
#' @importFrom runjags run.jags
#' @importFrom serocalculator get_biomarker_names
#' @importFrom serocalculator get_values
#' @importFrom serocalculator ids
#' @importFrom serocalculator ids_varname
#' @importFrom stats complete.cases
#' @importFrom stats quantile
#' @importFrom tidyr pivot_wider
#' @importFrom utils read.csv
## usethis namespace: end
NULL

# Stan availability note -------------------------------------------------------
#
# The Stan-based functions `run_mod_stan()`, `prep_data_stan()`, and
# `postprocess_stan_output()` require the `rstan` package, which is listed as
# a *suggested* (optional) dependency of serodynamics.  These functions call
# `requireNamespace("rstan")` at runtime and emit an informative error when
# rstan is not installed.
#
# To use the Stan backend, install rstan from CRAN.
#
# The Stan model file is stored in inst/stan/model_b.stan and is compiled on
# first use within each R session by `rstan::stan_model()`.
