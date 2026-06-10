#' Run Jags Model
#' @description
#'  `r lifecycle::badge("deprecated")`
#'  `run_mod()` was renamed to `run_serodynamics()` to create a more 
#'  descriptive function name.
#' @param ... Arguments passed to `run_serodynamics()`.
#' @seealso run_serodynamics()
#' @keywords internal
#' @export
run_mod <- function(...) {
  lifecycle::deprecate_warn(
    when = "0.1.0",
    what = "run_mod()",
    with = "run_serodynamics()"
  )
  
  run_serodynamics(...)
}
