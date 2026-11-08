# Prepare and validate a stratification list

`prep_strat_list()` builds the vector of stratum labels that
[`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr175/reference/run_serodynamics.md)
iterates over. When `strat` is `NA`, a single pseudo-stratum (`"None"`)
is returned so the model runs once on the full data set. Otherwise the
unique values of `data[[strat]]` are returned, with factor columns
coerced to their character labels so the loop iterates over labels
rather than the underlying integer codes. Rows with a missing
stratification value are dropped with a warning, since they cannot be
assigned to a stratum.

## Usage

``` r
prep_strat_list(data, strat)
```

## Arguments

- data:

  A [`base::data.frame()`](https://rdrr.io/r/base/data.frame.html)
  containing the stratification column.

- strat:

  A [character](https://rdrr.io/r/base/character.html) string naming the
  stratification column, or `NA` to run the model without
  stratification.

## Value

A vector of stratum labels to loop over.

## Author

Sam Schildhauer
