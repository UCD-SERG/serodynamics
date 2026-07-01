# serodynamics (development version)

## Internal

* Added a scheduled `Clean up PR Previews` workflow that prunes closed-PR `gh-pages` previews and compacts `gh-pages` history, so deleted render snapshots stop bloating the repo (closes #260).

## New features

* Added Stan support as an alternative to JAGS for Bayesian modeling:
  * New `run_mod_stan()` function for fitting models with Stan/cmdstanr.
  * New `prep_data_stan()` function to prepare data in Stan format.
  * New `prep_priors_stan()` function to prepare priors for Stan models.
  * New Stan model files: `inst/extdata/model.stan` and
    `inst/extdata/model.dobson.stan`.
  * Stan support is optional (`cmdstanr` in Suggests) and can be used
    alongside JAGS.
* Renamed user-facing functions for clarity (#241):
  - `run_mod()` → `run_serodynamics()`
  - `post_summ()` → `summarize_posterior()`
  - `plot_jags_trace()` → `plot_trace()`
  - `plot_jags_dens()` → `plot_density()`
  - `plot_jags_Rhat()` → `plot_rhat()`
  - `plot_jags_effect()` → `plot_ess()`
  **Breaking change:** old function names are no longer available, except
  `run_mod()`, which is still exported with a deprecation warning pointing
  to `run_serodynamics()`.
* Including optional population parameters as attributes in run_mod 
output. (#141)

## Bug fixes

* `run_mod()`'s `fitted_residuals` attribute now covers all observations across
  all strata (previously only the last stratum was retained) and always includes
  a `Stratification` column (`"None"` when unstratified). (#240)

## Developer-facing changes

* Documented in `CLAUDE.md`, `.github/copilot-instructions.md`, and a
  note in `.lintr.R` that `dplyr::*_join()` calls must specify the
  `relationship` argument (for example `relationship = "many-to-one"`),
  so an unexpected many-to-many match errors out instead of silently
  duplicating rows.
* The test suite now sets `options(lifecycle_verbosity = "error")` (via
  `tests/testthat/setup.R`), so tidyverse lifecycle deprecations -
  including soft deprecations such as using the `.data` pronoun in a
  tidy-selection context - fail the tests instead of passing silently.
* Updated the internals of `calc_fit_mod()` to use tidy-selection
  (`all_of()` and bare column-name strings) instead of the `.data`
  pronoun in `select()`, `.by`, and `pivot_wider()` contexts, removing
  a soft deprecation surfaced by the stricter test option above. No
  change to behavior or output.
* The `Claude Code Review` workflow now skips (rather than fails) when a
  bot triggered the run, so a commit pushed by `@claude` or the Copilot
  agent no longer produces a red review check.
* The `Claude Code Review` workflow now posts a fresh review comment per
  run and collapses the superseded ones as `OUTDATED`, so each push
  surfaces as new PR activity while older reviews fold up out of the way.
  `@claude` task comments are left untouched.
* Added `CLAUDE.md` and expanded the Code Style Guidelines in
  `.github/copilot-instructions.md` to direct reviewers (human and AI)
  to flag unnecessarily convoluted or non-idiomatic code - in
  particular data-masking used in tidy-selection contexts and
  `if`/`else` branching that only varies which columns are selected,
  renamed, or joined.
* Clarified Code Style Guidelines in `.github/copilot-instructions.md`:
  the UCD-SeRG Lab Manual takes precedence over the tidyverse style
  guide where they conflict, and functions should end with an explicit
  `return()` call per the lab manual / Google R Style Guide. This
  closes a gap where `@claude` reviews were flagging explicit returns
  as non-conforming.

# serodynamics 0.1.0

This is the first CRAN release of `serodynamics`, a package for Bayesian
hierarchical modeling of antibody kinetics from longitudinal serological
data. It serves as the upstream companion to the `serocalculator` package.

## New features

* Reorganized pkgdown documentation with new "Getting Started" guide 
demonstrating main API workflow, organized articles into "Get started" and 
"Developer Notes" sections (#73).
* Replacing old `nepal_sees_jags_output` data object with new `run_mod()` 
output (#102)
* Including `fitted_residuals` values as data frame attribute in `run_mod()` 
output. (#101)
* Adding `class` assignment to `run_mod()` output (#76)
* Making `prep_priors()` allow for modifiable inputs in `run_mod()` (#78)
* Exported `run_mod()` function (#22)
* Added attributes as a return to the `run_mod()` function (#24)
* Changes to `run_mod()` output:
  - Taking out `include_subs` as an input option, default will include all
  individuals
   `with_post`
   - all subjects now optionally included in `curve_params` output component, 
   as specified by argument `include_subs`
* A new `run_mod()` function that runs jags with option of stratification 
included. (#14)
* Diagnostic `plot_jags_Rhat()` function to produce R-hat dotplots with 
stratification (#67)
* Added `plot_summ()` function for summarizing estimates in a table (#74)
* Diagnostic `plot_jags_trace()` function to create a trace plot with 
stratifications (#64)
* Diagnostic `plot_jags_effect()` function to produce effective sample size 
plots with stratification (#66)
* Diagnostic `plot_jags_dens()` function to produce density plots with 
stratification (#27)
* Added `plot_predicted_curve()` with support for faceting by multiple IDs (#68)
* Fixing`nepal_sees` SEES data and added jags_post for SEES (#63)
* Added `nepal_sees` SEES data set data folder and documentation (#41)
* Added `postprocess_jags_output()` to API (#33)
* Added `initsfunction()` to API (#37)
* Added participant IDs as names to `nsmpl` element of `prep_data()` 
output (#34)
* Made "newperson" optional in `prep_data()` (#73)
* Added `initsfunction()` to API (#37)
* Added `as_case_data()` to API (#31)
* `as_case_data()` now creates column `visit_num` (#47, #50)
* Added `prep_priors()` to API (#30)
* Added `autoplot()` method for `case_data` objects (#28)
* Added examples for `sim_pop_data()`, `autoplot.case_data()` (#18)
* Changed package name to serodynamics. (#19, #20)

## Bug fixes

* Fixed `dplyr::as_tibble()` references to `tibble::as_tibble()` in 
`post_summ()` and `run_mod()`, since `as_tibble()` is exported from the 
`tibble` package, not `dplyr`.

## Developer-facing changes

* Added platform-aware snapshots and darwin-specific variants for macOS 
platform differences (#73).
* Updated Copilot instructions to encourage code decomposition and avoid
  copy-pasting substantial code chunks.
* Expanded `.github/copilot-instructions.md` with additional guidance on 
evidence-based claims, Quarto markdown/cross-reference conventions, R style 
practices, and phrase-level line-break formatting for source text.
* Added R 4.5+ snapshot variants to handle the changed attribute ordering in
  `as_case_data()`, ensuring test suite compatibility with R 4.5 and 
  later (#109).
* Added dev container configuration for persistent, cached development 
environment
  that includes R, JAGS, and all dependencies preinstalled, making Copilot
  Workspace sessions much faster.
* Added `.github/workflows/copilot-setup-steps.yml` GitHub Actions workflow to 
automate environment setup for GitHub Copilot coding agent, preinstalling R, 
JAGS, and all dependencies.
* Switched ggmcmc dependency from GitHub dev version to CRAN v1.5.1.2 (#135)
* vectorized `ab()` function (#116)
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
