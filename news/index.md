# Changelog

## serodynamics (development version)

- Expanded what the `Claude Code` (`@claude`) workflow can do:

  - Install the full R toolchain (R, JAGS, pandoc, the apt system libs
    mirrored from `copilot-setup-steps.yml`, plus `devtools`,
    `roxygen2`, `rmarkdown`, `lintr`, `spelling`, `rcmdcheck`) and allow
    `Rscript`, `R`, and `R CMD` invocations, so requests that need
    package- maintenance commands (`devtools::document()`,
    [`spelling::spell_check_package()`](https://docs.ropensci.org/spelling//reference/spell_check_package.html),
    `R CMD check`, vignette rebuilds) succeed instead of being patched
    by hand.
  - Grant `issues: write` and allow `gh issue` invocations so Claude can
    file follow-up issues for work deferred out of the current PR
    instead of burying it in a comment.

- Standardized
  [`runjags::findjags()`](https://rdrr.io/pkg/runjags/man/findjags.html)
  casing across `test-coverage.yaml` and `copilot-setup-steps.yml` to
  match the `R-CMD-check.yaml` form arriving with the 0.1.0 release
  ([\#207](https://github.com/UCD-SERG/serodynamics/issues/207)
  advisory).

- Re-assign reviewers to a PR’s human assignees (filtered via
  `type == "User"`) when Claude pushes commits during a `@claude` or
  `Claude Code Review` run; if Claude makes no commits, the original
  reviewer set is restored as before. Detected by comparing the PR’s
  head SHA before and after the Claude step
  ([\#210](https://github.com/UCD-SERG/serodynamics/issues/210)).

- Stopped deleting prior Claude review comments at the start of each
  `Claude Code Review` run, so reviews posted by `@claude review`
  invocations are preserved across subsequent pushes instead of being
  wiped when the review step fails its bot-actor gate
  ([\#217](https://github.com/UCD-SERG/serodynamics/issues/217)).

- Hardened the Claude code-review workflow against races and silent
  failures: serialized concurrent runs per PR, made reviewer restore
  fail loudly instead of silently dropping reviewers, and cleaned up all
  stale Claude top-level comments per run
  ([\#216](https://github.com/UCD-SERG/serodynamics/issues/216)).

- Expanded `.github/copilot-instructions.md` with additional guidance on
  evidence-based claims, Quarto markdown/cross-reference conventions, R
  style practices, and phrase-level line-break formatting for source
  text.

- Fixed
  [`dplyr::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
  references to
  [`tibble::as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
  in
  [`post_summ()`](https://ucd-serg.github.io/serodynamics/reference/post_summ.md)
  and
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/reference/run_mod.md),
  since
  [`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
  is exported from the `tibble` package, not `dplyr`.

- Added R 4.5+ snapshot variants to handle the changed attribute
  ordering in
  [`as_case_data()`](https://ucd-serg.github.io/serodynamics/reference/as_case_data.md),
  ensuring test suite compatibility with R 4.5 and later
  ([\#109](https://github.com/UCD-SERG/serodynamics/issues/109)).

- Added dev container configuration for persistent, cached development
  environment that includes R, JAGS, and all dependencies preinstalled,
  making Copilot Workspace sessions much faster.

- Reorganized pkgdown documentation with new “Getting Started” guide
  demonstrating main API workflow, organized articles into “Get started”
  and “Developer Notes” sections
  ([\#73](https://github.com/UCD-SERG/serodynamics/issues/73)).

- Added `.github/workflows/copilot-setup-steps.yml` GitHub Actions
  workflow to automate environment setup for GitHub Copilot coding
  agent, preinstalling R, JAGS, and all dependencies.

- Consolidated OS-specific snapshot variants: removed redundant Linux
  and Windows snapshot directories (which were identical), keeping only
  base snapshots and darwin-specific variants for macOS platform
  differences
  ([\#73](https://github.com/UCD-SERG/serodynamics/issues/73)).

- Initial CRAN submission.

- Updated Copilot instructions to encourage code decomposition and avoid
  copy-pasting substantial code chunks.

### New features

- Made “newperson” optional in
  [`prep_data()`](https://ucd-serg.github.io/serodynamics/reference/prep_data.md)
  ([\#73](https://github.com/UCD-SERG/serodynamics/issues/73))
- Including fitted and residual values as data frame in run_mod output.
  ([\#101](https://github.com/UCD-SERG/serodynamics/issues/101))
- Added
  [`plot_predicted_curve()`](https://ucd-serg.github.io/serodynamics/reference/plot_predicted_curve.md)
  with support for faceting by multiple IDs
  ([\#68](https://github.com/UCD-SERG/serodynamics/issues/68))
- Replacing old data object with new run_mod output
  ([\#102](https://github.com/UCD-SERG/serodynamics/issues/102))
- Adding class assignment to run_mod output
  ([\#76](https://github.com/UCD-SERG/serodynamics/issues/76))
- Making prep_priors modifiable
  ([\#78](https://github.com/UCD-SERG/serodynamics/issues/78))
- Changes to
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/reference/run_mod.md)
  output:
  - Taking out `include_subs` as an input option, default will include
    all individuals
  - Making a single tbl as output
  - All other pieces will be attributes.
- Changes to
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/reference/run_mod.md)
  ([\#79](https://github.com/UCD-SERG/serodynamics/issues/79)):
  - `jags.post` now optionally included in output, as specified by
    argument `with_post`
  - all subjects now optionally included in `curve_params` output
    component, as specified by argument `include_subs`
- Diagnostic function to produce R-hat dotplots with stratification
  ([\#67](https://github.com/UCD-SERG/serodynamics/issues/67))
- Added function for summarizing estimates in a table
  ([\#74](https://github.com/UCD-SERG/serodynamics/issues/74))
- Diagnostic trace plot function with strat
  ([\#64](https://github.com/UCD-SERG/serodynamics/issues/64))
- Diagnostic function to produce effective sample size plots with
  stratification
  ([\#66](https://github.com/UCD-SERG/serodynamics/issues/66))
- Diagnostic function to produce density plots with stratification
  ([\#27](https://github.com/UCD-SERG/serodynamics/issues/27))
- Added SEES data set data folder and documentation
  ([\#41](https://github.com/UCD-SERG/serodynamics/issues/41))
- Fixing SEES data and added jags_post for SEES
  ([\#63](https://github.com/UCD-SERG/serodynamics/issues/63))
- [`as_case_data()`](https://ucd-serg.github.io/serodynamics/reference/as_case_data.md)
  now creates column `visit_num`
  ([\#47](https://github.com/UCD-SERG/serodynamics/issues/47),
  [\#50](https://github.com/UCD-SERG/serodynamics/issues/50))
- Added
  [`postprocess_jags_output()`](https://ucd-serg.github.io/serodynamics/reference/postprocess_jags_output.md)
  to API ([\#33](https://github.com/UCD-SERG/serodynamics/issues/33))
- Added
  [`initsfunction()`](https://ucd-serg.github.io/serodynamics/reference/initsfunction.md)
  to API ([\#37](https://github.com/UCD-SERG/serodynamics/issues/37))
- Added participant IDs as names to `nsmpl` element of
  [`prep_data()`](https://ucd-serg.github.io/serodynamics/reference/prep_data.md)
  output ([\#34](https://github.com/UCD-SERG/serodynamics/issues/34))
- Added
  [`initsfunction()`](https://ucd-serg.github.io/serodynamics/reference/initsfunction.md)
  to API ([\#37](https://github.com/UCD-SERG/serodynamics/issues/37))
- Added
  [`as_case_data()`](https://ucd-serg.github.io/serodynamics/reference/as_case_data.md)
  to API ([\#31](https://github.com/UCD-SERG/serodynamics/issues/31))
- Added
  [`prep_priors()`](https://ucd-serg.github.io/serodynamics/reference/prep_priors.md)
  to API ([\#30](https://github.com/UCD-SERG/serodynamics/issues/30))
- Added
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  method for `case_data` objects
  ([\#28](https://github.com/UCD-SERG/serodynamics/issues/28))
- Added examples for `sim_pop_data()`,
  [`autoplot.case_data()`](https://ucd-serg.github.io/serodynamics/reference/autoplot.case_data.md)
  ([\#18](https://github.com/UCD-SERG/serodynamics/issues/18))
- Added attributes as a return to the run_mod function
  ([\#24](https://github.com/UCD-SERG/serodynamics/issues/24))
- exported
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/reference/run_mod.md)
  function ([\#22](https://github.com/UCD-SERG/serodynamics/issues/22))
- Function that runs jags with option of stratification included.
  ([\#14](https://github.com/UCD-SERG/serodynamics/issues/14))
- Changed package name to serodynamics.
  ([\#19](https://github.com/UCD-SERG/serodynamics/issues/19),
  [\#20](https://github.com/UCD-SERG/serodynamics/issues/20))

### Bug fixes

None yet

### Developer-facing changes

- Switched ggmcmc dependency from GitHub dev version to CRAN v1.5.1.2
  ([\#135](https://github.com/UCD-SERG/serodynamics/issues/135))
- vectorized `ab()` function
  ([\#116](https://github.com/UCD-SERG/serodynamics/issues/116))
- Added `lintr::undesirable_function_linter()` to `.lintr.R`
  ([\#81](https://github.com/UCD-SERG/serodynamics/issues/81))
- Reformatted `.lintr` as R file (following
  <https://github.com/r-lib/lintr/issues/2844#issuecomment-2776725389>)
  ([\#81](https://github.com/UCD-SERG/serodynamics/issues/81))
- Set shortcut pipe to be base pipe
  ([\#80](https://github.com/UCD-SERG/serodynamics/issues/80))
- Added snapshot test for
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/reference/run_mod.md)
- Clarified
  [`prep_data()`](https://ucd-serg.github.io/serodynamics/reference/prep_data.md)
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
  [`prep_data()`](https://ucd-serg.github.io/serodynamics/reference/prep_data.md),
  [`sim_case_data()`](https://ucd-serg.github.io/serodynamics/reference/sim_case_data.md)
  ([\#18](https://github.com/UCD-SERG/serodynamics/issues/18))
- Added various GitHub Actions
  ([\#10](https://github.com/UCD-SERG/serodynamics/issues/10),
  [\#15](https://github.com/UCD-SERG/serodynamics/issues/15),
  [\#18](https://github.com/UCD-SERG/serodynamics/issues/18))

## serodynamics 0.0.0

Started development.
