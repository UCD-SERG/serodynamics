# Relabel `prec.logy` population parameters by isotype

`relabel_preclogy_iso()` replaces the `Param` label of `prec.logy`
population-parameter rows with their antigen/isotype label (`Iso_type`).
This lets callers group `population_params` by `Parameter` to obtain
per-isotype precision estimates, rather than collapsing all isotypes
into a single `"prec.logy"` group. Rows that are not `prec.logy`
population parameters, and rows lacking an `Iso_type` (e.g., the
scalar/unindexed case), are left unchanged.

## Usage

``` r
relabel_preclogy_iso(jags_unpacked)
```

## Arguments

- jags_unpacked:

  A
  [tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
  returned by
  [`unpack_jags()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/unpack_jags.md)
  after the `Iso_type` join, containing `.is_population_parameter`,
  `Subject`, `Iso_type`, and `Param` columns.

## Value

The input with `Param` relabeled to `Iso_type` for `prec.logy`
population-parameter rows.

## Author

Sam Schildhauer
