# serodynamics (development version)

## Internal

* Removed the `.ai-config` git submodule, its `.gitmodules` entry, and the
  scheduled `Bump submodule` workflow (#316). The `ai-config`
  Claude Code plugin registered in `.claude/settings.json` supplies the same
  corpus without a second copy to keep pinned.

* Granted `pull-requests: write` permission to the review dispatch job in
  `claude-code-review.yml` (#307), allowing acknowledgment comments to post on
  pull requests without GraphQL permission errors.

* Hardened JAGS download and installer execution across CI workflows
  (`R-CMD-check.yaml` and `test-coverage.yaml`), using `curl.exe` with retry
  flags, `start /wait` for synchronous Windows installer execution, and platform-
  tailored `rjags` installation (`type = "source"` on macOS/Linux, binary on
  Windows).

* Regenerated `NAMESPACE` and `DESCRIPTION` under roxygen2 8.1.0 (#288).
  The documentation check installs whatever roxygen2 is current rather than a
  fixed version, so the 8.1.0 release started rewriting both files against the
  8.0.0 they were generated with, and the check failed on every pull request
  -- including ones that touch no R code at all.
  The `NAMESPACE` change is formatting only: where several symbols come from
  one package, 8.1.0 groups them into a single `importFrom()` call instead of
  writing a line for each.
  Parsing both versions gives the same 22 exports, 27 imports and one S3
  method.
  `DESCRIPTION` moves to `Config/roxygen2/version: 8.1.0` and drops the older
  `RoxygenNote` field, which 8.1.0 no longer writes.
  The version is left floating rather than fixed, so a later roxygen2 release
  will need the same treatment.

* Restored `@claude review` as a way to request a review (#285).
  Disabling the agent bot moved review dispatch into
  `claude-code-review.yml` behind a comment starting with `/review`, on the
  reasoning that the mention form belonged to `claude.yml` -- which had just
  been switched off.
  So `@claude review` stopped doing anything at all, and did so silently:
  both jobs skipped, nothing went red, and the person asking got no reply.
  All three review requests made in the twelve days that followed used the
  mention form and were ignored; `/review` was never typed once.
  Both spellings now work.
  The mention is matched with `Morrison-Lab/gha`'s own
  `detect-review-request` action rather than a pattern of our own, so an
  agent task
  (`@claude, please fix the failing test`) is still not mistaken for a review
  request, and a mention quoted in a code span or a quoted line does not
  trigger one.
* Replaced the silence with a reply when the `@claude` agent is addressed.
  A mention that is not a review request now gets a short comment saying the
  agent is switched off and naming the triggers that do work, since a skipped
  workflow is indistinguishable from a broken bot -- which is why the gap
  above went unnoticed for so long.
* Disabled the `@claude` agent bot.
  `.github/workflows/claude.yml`'s reactive triggers are commented out and its
  job carries `if: false`, so no comment, issue, or review event invokes the
  agent, and neither does a manual dispatch (the reusable workflow runs
  unattended on `workflow_dispatch` by design).
  Reviews are the only Claude capability left, and they run on request only:
  comment `/review` on a pull request.
  That path is new here -- `claude-code-review.yml` gained an `issue_comment`
  trigger and a `dispatch-on-comment` job, since the `@claude review` mention
  it previously relied on went away with the agent.
* Pointed the `ai-config` Claude Code plugin marketplace at `Morrison-Lab`.
  The corpus moved to a new GitHub organization and renamed the marketplace
  declared in its own `.claude-plugin/marketplace.json`.
  A plugin reference resolves by that declared name, so
  `.claude/settings.json`'s `ai-config@d-morrison` matched nothing and aborted
  plugin installation in cloud and web sessions opened on this repo.
  The clone URL was never the problem, since git follows GitHub's transfer
  redirect; only the name lookup failed.
  `.gitmodules` and `CLAUDE.md`'s live links now point at the new organization
  as well.
* Removed the local `dispatch-explicit-review` job from `.github/workflows/claude.yml`.
  It existed to cover `@claude, please review`, a phrasing the reusable workflow's own
  pattern missed (#277), but that pattern has since been broadened upstream in
  [`d-morrison/gha#341`](https://github.com/d-morrison/gha/pull/341).
  With both patterns live, a plain `@claude review` dispatched two paid review runs,
  which could review different heads because the local job had no `needs: claude`
  (closes #277, closes #276).
* Added a project-level `Claude Code` skill, `reprexes`
  (`.claude/skills/reprexes`), capturing a workflow for isolating a problem
  into a minimal reproducible example and iterating fixes on it before
  porting them back (#239).
* Embedded [`d-morrison/ai-config`](https://github.com/d-morrison/ai-config) as a `.ai-config` git submodule, with a scheduled `Bump submodule` workflow to keep the pin fresh, and registered its Claude Code plugin marketplace in `.claude/settings.json` so cloud/web sessions opened on this repo load its skills (closes #264).
* Added a scheduled `Clean up PR Previews` workflow that prunes closed-PR `gh-pages` previews and compacts `gh-pages` history, so deleted render snapshots stop bloating the repo (closes #260).
* Added a `CLAUDE.md` review-guideline item flagging roxygen doc copy-paste (use `@inheritParams`/`@inheritDotParams`/`@inheritSection` instead) and manual argument relaying (use `...` passthrough instead) (closes #262).

## New features
* Added `plot_residuals()` to visualize residuals over time, faceted by
  antigen-isotype. `run_serodynamics()` stores the original input `data`
  (and the stratification variable name) as `original_data`/`strat`
  attributes; `plot_residuals()` computes fitted and residual values on
  demand from those attributes via `calc_fit_mod()`, which returns
  2.5%/97.5% posterior quantiles for each residual on both the natural
  scale (`residual_low`, `residual_high`) and the log10 scale
  (`log_residual`, `log_residual_low`, `log_residual_high`),
  which `plot_residuals()` uses to draw a precision interval around each
  point. `fitted_residuals` is no longer added as an attribute. (#230).
* Added an exponential decay option for antibody decay curves via `decay_type`.
  (#252)
* Added `plot_serocurve()` for graphical visualization of population-level
  serodynamic curves using posterior samples of the predictive `newperson`
  parameter distribution (or optionally the population level hyperparameter
  distributions).
  Supports 95% credible interval ribbons, stratified curves with color or
  faceting, and multiple antigen-isotypes (#74).
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
* `calc_fit_mod()`'s output now covers all observations across
all strata (previously only the last stratum was retained) and always includes
a `Stratification` column (`"None"` when unstratified). (#240)
* `plot_residuals()`/`calc_fit_mod()` now forward the `decay_type` attribute
  stored by `run_serodynamics()` through to `ab()`. Previously the argument
  was silently dropped, so exponential-decay models were fitted with the
  power-decay formula; since exponential decay's `shape` is fixed at `1`,
  this made every post-peak `fitted` value collapse to exactly `1`. (#230)

## Developer-facing changes
* Cut down on `run_serodynamics()` tests to lower run time/load. 
Went from 5 separate `run.jags` chunks down to 3. (#253)
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
