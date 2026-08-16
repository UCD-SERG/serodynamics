# Extracts Residuals for Plotting

Filters and reshapes fitted/residual values (and their posterior
quantiles), on the requested scale, for plotting. Ensure expected
residual columns exist. These are normally supplied by calc_fit_mod(),
but fill missing columns defensively.

## Usage

``` r
residuals_from_fit_res(fit_res, ids, antigen_isos, log_y)
```

## Arguments

- fit_res:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) of fitted and
  residual values, as returned by
  [`calc_fit_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr230/reference/calc_fit_mod.md).

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

## Value

A
[tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
ready to plot.
