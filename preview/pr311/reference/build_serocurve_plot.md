# Creates Plot for Estimated Serodynamic Curves

Assembles the full
[`plot_serocurve()`](https:/ucd-serg.github.io/serodynamics/preview/pr311/reference/plot_serocurve.md)
ggplot object (bands, faceting, log scales, and custom x-axis limits)
from a summarised curve tibble.

## Usage

``` r
build_serocurve_plot(
  curve_summary,
  show_ci,
  multi_strat,
  antigen_iso,
  antigen_iso_col,
  log_y,
  log_x,
  xlim,
  facet_by_strat,
  ...
)
```

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.
