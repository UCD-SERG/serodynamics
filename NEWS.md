# serodynamics (development version)

* Initial CRAN submission.

## New features

* Diagnostic function to produce R-hat dotplots with stratification (#67)
* Added function for summarizing estimates in a table (#74)
* Diagnostic trace plot function with strat (#64)
* Diagnostic function to produce effective sample size plots with
stratification (#66)
* Diagnostic function to produce density plots with stratification (#27)
* Added SEES data set data folder and documentation (#41)
* Fixing SEES data and added jags_post for SEES (#63)
* `as_case_data()` now creates column `visit_num` (#47, #50)
* Added `postprocess_jags_output()` to API (#33)
* Added `initsfunction()` to API (#37)
* Added participant IDs as names to `nsmpl` element of `prep_data()` output (#34)
* Added `initsfunction()` to API (#37)
* Added `as_case_data()` to API (#31)
* Added `prep_priors()` to API (#30)
* Added `autoplot()` method for `case_data` objects (#28)
* Added examples for `sim_pop_data()`, `autoplot.case_data()` (#18)
* Added attributes as a return to the run_mod function (#24)
* exported `run_mod()` function (#22)
* Function that runs jags with option of stratification included. (#14)
* Changed package name to serodynamics. (#19, #20)

## Bug fixes

None yet

## Developer-facing changes

* Added `lintr::undesirable_function_linter()` to `.lintr.R` (#81)
* Reformatted `.lintr` as R file (following 
https://github.com/r-lib/lintr/issues/2844#issuecomment-2776725389) (#81)
* Set shortcut pipe to be base pipe (#80)
* Added snapshot test for `run_mod()`
* Clarified `prep_data()` internals using `{dplyr}` (#34)
* Removed ".R" suffix from jags model files 
to prevent them from getting linted as R files (#34)
* Added `dobson.Rmd` minimal vignette (#36)
* Overall cleaning to get checks working (#28)
* Added units tests for `prep_data()`, `sim_case_data()` (#18)
* Added various GitHub Actions (#10, #15, #18)

# serodynamics 0.0.0

Started development.
