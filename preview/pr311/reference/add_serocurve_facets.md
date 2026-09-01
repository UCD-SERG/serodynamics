# Establishes Facets when Building Serocurve

Facets a
[`plot_serocurve()`](https:/ucd-serg.github.io/serodynamics/preview/pr311/reference/plot_serocurve.md)
plot by antigen-isotype and/or Stratification, choosing a sensible
default `ncol` when one isn't supplied.

## Usage

``` r
add_serocurve_facets(
  p,
  curve_summary,
  antigen_iso_col,
  antigen_iso,
  facet_by_strat,
  facet_by_antigen_iso = length(antigen_iso) > 1,
  ncol = NULL
)
```

## Arguments

- facet_by_antigen_iso:

  [logical](https://rdrr.io/r/base/logical.html); if
  [TRUE](https://rdrr.io/r/base/logical.html), facets the plot by
  antigen-isotype. Defaults to
  [TRUE](https://rdrr.io/r/base/logical.html) when multiple
  antigen-isotypes are requested.

- ncol:

  [integer](https://rdrr.io/r/base/integer.html); number of columns when
  faceting. If [NULL](https://rdrr.io/r/base/NULL.html) (default), a
  sensible value is chosen automatically.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object with facets.
