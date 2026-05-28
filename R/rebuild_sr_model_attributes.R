#' @title Rebuild `sr_model` output attributes in a stable order
#' @author Sam Schildhauer
#' @description
#'  `rebuild_sr_model_attributes()` reconstructs the attribute list of the
#'  combined [run_serodynamics()] output in a fixed order, ensuring `class` appears
#'  immediately after `names` and `row.names`.
#'  The `dplyr` operations used to assemble the output can carry `ggmcmc`
#'  attributes (`nChains`, etc.) into the result and push `class` to the end,
#'  so this helper rebuilds the attributes explicitly. `mod_atts` (a named
#'  selection from the `ggmcmc::ggs()` object) is the authoritative source for
#'  the `ggmcmc`-style metadata attributes.
#' @param x A [data.frame] / [tibble::tbl_df] of combined MCMC output.
#' @param mod_atts A named [list] of `ggmcmc` metadata attributes, containing
#'  `nChains`, `nParameters`, `nIterations`, `nBurnin`, and `nThin`.
#' @returns `x` with its attributes rebuilt in a stable order and the
#'  `sr_model` class prepended.
#' @keywords internal
rebuild_sr_model_attributes <- function(x, mod_atts) {
  current_atts <- attributes(x)
  new_atts <- list(
    names = current_atts$names,
    row.names = current_atts$row.names,
    class = union("sr_model", current_atts$class),
    nChains = mod_atts$nChains,
    nParameters = mod_atts$nParameters,
    nIterations = mod_atts$nIterations,
    nBurnin = mod_atts$nBurnin,
    nThin = mod_atts$nThin
  )
  attributes(x) <- new_atts
  x
}
