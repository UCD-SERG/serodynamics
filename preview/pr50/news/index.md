# Changelog

## serodynamics (development version)

- Initial CRAN submission.

### New features

- Added
  [`postprocess_jags_output()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/postprocess_jags_output.md)
  to API ([\#33](https://github.com/UCD-SERG/serodynamics/issues/33))
- Added
  [`initsfunction()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/initsfunction.md)
  to API ([\#37](https://github.com/UCD-SERG/serodynamics/issues/37))
- Added participant IDs as names to `nsmpl` element of
  [`prep_data()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/prep_data.md)
  output ([\#34](https://github.com/UCD-SERG/serodynamics/issues/34))
- Added
  [`initsfunction()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/initsfunction.md)
  to API ([\#37](https://github.com/UCD-SERG/serodynamics/issues/37))
- Added
  [`as_case_data()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/as_case_data.md)
  to API ([\#31](https://github.com/UCD-SERG/serodynamics/issues/31))
- Added
  [`prep_priors()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/prep_priors.md)
  to API ([\#30](https://github.com/UCD-SERG/serodynamics/issues/30))
- Added
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  method for `case_data` objects
  ([\#28](https://github.com/UCD-SERG/serodynamics/issues/28))
- Added examples for `sim_pop_data()`,
  [`autoplot.case_data()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/autoplot.case_data.md)
  ([\#18](https://github.com/UCD-SERG/serodynamics/issues/18))
- Added attributes as a return to the run_mod function
  ([\#24](https://github.com/UCD-SERG/serodynamics/issues/24))
- exported
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/run_mod.md)
  function ([\#22](https://github.com/UCD-SERG/serodynamics/issues/22))
- Function that runs jags with option of stratification included.
  ([\#14](https://github.com/UCD-SERG/serodynamics/issues/14))
- Changed package name to serodynamics.
  ([\#19](https://github.com/UCD-SERG/serodynamics/issues/19),
  [\#20](https://github.com/UCD-SERG/serodynamics/issues/20))

### Bug fixes

None yet

### Developer-facing changes

- Added snapshot test for
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/run_mod.md)
- Clarified
  [`prep_data()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/prep_data.md)
  internals using [dplyr](https://dplyr.tidyverse.org)
  ([\#34](https://github.com/UCD-SERG/serodynamics/issues/34))
- Removed “.R” suffix from jags model files to prevent them from getting
  linted as R files
  ([\#34](https://github.com/UCD-SERG/serodynamics/issues/34))
- Added `dobson.Rmd` minimal vignette
  ([\#36](https://github.com/UCD-SERG/serodynamics/issues/36))
- Overall cleaning to get checks working
  ([\#28](https://github.com/UCD-SERG/serodynamics/issues/28))
- Added units tests for
  [`prep_data()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/prep_data.md),
  [`sim_case_data()`](https://ucd-serg.github.io/serodynamics/preview/pr50/reference/sim_case_data.md)
  ([\#18](https://github.com/UCD-SERG/serodynamics/issues/18))
- Added various GitHub Actions
  ([\#10](https://github.com/UCD-SERG/serodynamics/issues/10),
  [\#15](https://github.com/UCD-SERG/serodynamics/issues/15),
  [\#18](https://github.com/UCD-SERG/serodynamics/issues/18))
