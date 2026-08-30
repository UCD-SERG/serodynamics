# Plot Residuals Over Time

Plots residuals over time and facets by antigen-isotype (`Iso_type`).
The mean absolute residual for each facet is annotated in the
upper-right corner. Fitted and residual values are calculated on demand
via
[`calc_fit_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr284/reference/calc_fit_mod.md),
using the `original_data`, `strat`, and `decay_type` attributes stored
on `model` by
[`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr284/reference/run_serodynamics.md),
and include both natural-scale and log10-scale medians and 2.5%/97.5%
posterior quantiles.

## Usage

``` r
plot_residuals(
  model,
  ids = NULL,
  antigen_isos = NULL,
  log_y = TRUE,
  show_interval = TRUE,
  connect_lines = FALSE
)
```

## Arguments

- model:

  An `sr_model` object (returned by
  [`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr284/reference/run_serodynamics.md)),
  with `original_data`, `strat`, and `decay_type` attributes (see
  [`calc_fit_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr284/reference/calc_fit_mod.md)).

- ids:

  (Optional) Participant IDs to include. When supplied, points (and, if
  `connect_lines = TRUE`, lines) are colored by subject; otherwise no
  color is used.

- antigen_isos:

  (Optional) Antigen-isotypes (`antigen_iso`) to include.

- log_y:

  [logical](https://rdrr.io/r/base/logical.html); if `TRUE` (default),
  plots the residual computed on the log10 scale
  (`log10(observed) - log10(fitted)`); if `FALSE`, plots the
  natural-scale residual.

- show_interval:

  [logical](https://rdrr.io/r/base/logical.html); if `TRUE` (default),
  draws an error bar around each residual spanning its 2.5%/97.5%
  posterior interval, to visualize the precision of the posterior.

- connect_lines:

  [logical](https://rdrr.io/r/base/logical.html); if `TRUE`, connects
  each subject's residuals over time with a line. Default `FALSE`.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
plot_residuals(
  model = serodynamics::nepal_sees_jags_output,
  ids = c("sees_npl_128", "sees_npl_131"),
  antigen_isos = c("HlyE_IgA", "HlyE_IgG")
)
```
