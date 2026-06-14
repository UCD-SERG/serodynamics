# Claude / AI agent instructions for serodynamics

This file is read by Claude Code sessions and by the `@claude` GitHub
review agent. The canonical, detailed contributor guide lives in
[`.github/copilot-instructions.md`](.github/copilot-instructions.md) —
**follow it** for setup, build, test, documentation, and style. This
file adds review-specific emphasis on top of that guide.

## Lab-wide style authority

Follow the
[UCD-SeRG Lab Manual coding-style chapter](https://ucd-serg.github.io/lab-manual/coding-style.html)
first; fall back to the [tidyverse style guide](https://style.tidyverse.org)
only where the lab manual is silent. Where the two conflict, the lab
manual wins.

## Idiomatic-code review focus

Beyond correctness, flag code that is functionally fine but
unnecessarily convoluted or non-idiomatic, and suggest the idiomatic
form. Treat these as in-scope review findings, not optional nits:

- **Data-masking in tidy-selection contexts.** Flag the `.data` pronoun
  (`.data$x`, `.data[[var]]`) used inside *selection* contexts —
  `select()`, `rename()`, `summarize(.by = )` / `group_by()`,
  `across(.cols = )`, `pivot_*(names_from = )`, and join `by =`. Use
  `all_of()` / `any_of()` to select columns named by a variable, and
  bare column names (or `all_of()`) in `.by`. The `.data` pronoun
  belongs in *data-masking* verbs (`mutate()`, `filter()`,
  `summarize()` expressions), not in selection. Note that
  `.data[[var]]` in a selection context is a *soft* deprecation, so it
  may not emit a warning at runtime — flag it on sight.

- **Branching that only varies columns.** Flag `if`/`else` whose sole
  purpose is to vary which columns are selected, renamed, or joined.
  These usually collapse into a single `any_of()` / `all_of()`
  selection (e.g. `select(any_of(c(..., "Stratification" = strat)))`)
  or a single join with a tidyselect `by =`, removing the branch
  entirely.

- **Base `merge()` over dplyr joins.** Prefer `dplyr::left_join()` /
  `right_join()` with `by = join_by(...)` for clarity and consistency
  with the rest of the codebase.

- **dplyr `*_join()` calls must set `relationship`.** Flag any
  `dplyr::left_join()` / `right_join()` / `inner_join()` / `full_join()`
  that omits the `relationship` argument. Stating the expected
  cardinality explicitly (e.g. `relationship = "many-to-one"`) makes the
  join's intent clear and turns an unexpected many-to-many match into an
  error instead of a silent row explosion. See
  [PR #240](https://github.com/UCD-SERG/serodynamics/pull/240/changes#diff-58597f8513171a9da41d8e6c89e4230df8879139a10dd2422aa659aa496dd29eR52-R58)
  for an example.

- **Near-duplicate stratified / unstratified paths.** Prefer one
  parameterized pipeline over two near-identical branches.

- Generally: when a more declarative tidyverse construct expresses the
  same thing with less control flow, say so and show the simpler form.

## Deprecation strictness

The test suite sets `options(lifecycle_verbosity = "error")` (see
`tests/testthat/setup.R`), so lifecycle deprecations — including
`.data`-in-tidyselect — fail the tests rather than passing silently.
Keep new code free of deprecated calls.
