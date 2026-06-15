# Reconcile MCMC subject indices with subject IDs

`reconcile_subject_ids()` joins unpacked MCMC output to the subject ID
lookup table and resolves a single `Subject` identifier for every row.

- Individual-level parameters match a row in `ids`, so they receive the
  original subject ID.

- Population-level parameters (e.g., `mu.par`, `prec.par`, `prec.logy`)
  have no matching ID, so they retain the parameter name produced by
  [`unpack_jags()`](https:/ucd-serg.github.io/serodynamics/preview/pr241/reference/unpack_jags.md)
  as their identifier. The temporary index columns are then dropped and
  the cleaned parameter names (`Param`) are promoted to `Parameter` for
  downstream use.

## Usage

``` r
reconcile_subject_ids(jags_unpacked, ids)
```

## Arguments

- jags_unpacked:

  A
  [tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
  returned by
  [`unpack_jags()`](https:/ucd-serg.github.io/serodynamics/preview/pr241/reference/unpack_jags.md)
  (after the `Iso_type` join), containing `Subject`, `Subnum`, `Param`,
  and `Parameter` columns.

- ids:

  A
  [tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
  with a `Subject_mcmc` column (the subject ID) and a `Subject` column
  (the MCMC index as a character string).

## Value

A
[tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
with a single resolved `Subject` column and a `Parameter` column holding
the cleaned parameter name.

## Author

Sam Schildhauer
