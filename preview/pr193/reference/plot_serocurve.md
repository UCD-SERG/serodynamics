# Plot Estimated Serodynamic Curves at the Population Level

Plots the estimated antibody response curve derived from posterior
samples of population-level (`mu.par`) or the predictive distribution
from a fitted
[`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/run_serodynamics.md)
model. A median curve with an optional 95% credible interval ribbon is
produced for each requested antigen-isotype and stratification
combination.

## Usage

``` r
plot_serocurve(
  model,
  antigen_iso = unique(model$Iso_type),
  strat = unique(model$Stratification),
  param_source = "predictive",
  show_ci = TRUE,
  log_y = FALSE,
  log_x = FALSE,
  xlim = NULL,
  facet_by_antigen_iso = length(antigen_iso) > 1,
  facet_by_strat = FALSE,
  ncol = NULL
)
```

## Arguments

- model:

  An `sr_model` object returned by
  [`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/run_serodynamics.md).

- antigen_iso:

  A [character](https://rdrr.io/r/base/character.html) vector of
  antigen-isotype combinations to plot. Defaults to all antigen-isotypes
  present in the subject-level draws of `model` (`model$Iso_type`); in
  normal usage these match the levels available in
  `attr(model, "population_params")`.

- strat:

  A [character](https://rdrr.io/r/base/character.html) vector of
  stratification levels to include. Defaults to all stratification
  levels present in the subject-level draws of `model`
  (`model$Stratification`); in normal usage these match the levels
  available in `attr(model, "population_params")`.

- param_source:

  [character](https://rdrr.io/r/base/character.html); which posterior
  samples to use for the curve. Options:

  - `"predictive"` (default): uses the predictive distribution for a new
    individual drawn from the population-level prior.

  - `"population"`: uses population-level `mu.par` samples stored in
    `attr(model, "population_params")`. Requires the model to have been
    fitted with `run_serodynamics(..., with_pop_params = TRUE)`.

- show_ci:

  [logical](https://rdrr.io/r/base/logical.html); if
  [TRUE](https://rdrr.io/r/base/logical.html) (default), draws a 95%
  credible interval ribbon around the median curve.

- log_y:

  [logical](https://rdrr.io/r/base/logical.html); if
  [TRUE](https://rdrr.io/r/base/logical.html), applies a
  [log10](https://rdrr.io/r/base/Log.html) transformation to the y-axis.
  Defaults to [FALSE](https://rdrr.io/r/base/logical.html).

- log_x:

  [logical](https://rdrr.io/r/base/logical.html); if
  [TRUE](https://rdrr.io/r/base/logical.html), applies a pseudo-log10
  transformation to the x-axis. Defaults to
  [FALSE](https://rdrr.io/r/base/logical.html).

- xlim:

  (Optional) A numeric vector of length 2 giving custom x-axis limits.

- facet_by_antigen_iso:

  [logical](https://rdrr.io/r/base/logical.html); if
  [TRUE](https://rdrr.io/r/base/logical.html), facets the plot by
  antigen-isotype. Defaults to
  [TRUE](https://rdrr.io/r/base/logical.html) when multiple
  antigen-isotypes are requested.

- facet_by_strat:

  [logical](https://rdrr.io/r/base/logical.html); if
  [TRUE](https://rdrr.io/r/base/logical.html), facets the plot by
  stratification level. When
  [FALSE](https://rdrr.io/r/base/logical.html) (default), different
  stratification levels are shown as different colours on the same
  panel.

- ncol:

  [integer](https://rdrr.io/r/base/integer.html); number of columns when
  faceting. If [NULL](https://rdrr.io/r/base/NULL.html) (default), a
  sensible value is chosen automatically.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
# nepal_sees_jags_output already includes population_params
model <- serodynamics::nepal_sees_jags_output

# Population-level curve for a single antigen-isotype and stratum
p1 <- plot_serocurve(
  model       = model,
  antigen_iso = "HlyE_IgA",
  strat       = "typhi"
)
print(p1)


# Population-level curves for both stratifications, coloured by stratum
p2 <- plot_serocurve(
  model       = model,
  antigen_iso = "HlyE_IgA"
)
print(p2)


# Facet by stratification instead of colouring
p3 <- plot_serocurve(
  model          = model,
  antigen_iso    = "HlyE_IgA",
  facet_by_strat = TRUE
)
print(p3)


# Multiple antigen-isotypes, faceted, without CI
p4 <- plot_serocurve(
  model                = model,
  antigen_iso          = c("HlyE_IgA", "HlyE_IgG"),
  facet_by_antigen_iso = TRUE,
  show_ci              = FALSE
)
print(p4)


# Using the predictive distribution for a new individual
p5 <- plot_serocurve(
  model        = model,
  antigen_iso  = "HlyE_IgA",
  param_source = "predictive"
)
print(p5)
```
