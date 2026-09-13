# Assigns column names to conform with [`calc_fit_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/calc_fit_mod.md) using attributes

`use_att_names` takes prepared longitudinal data for antibody kinetic
modeling and names columns using attribute values to allow merging with
a modeled
[`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/run_mod.md)
output
[dplyr::tbl_df](https://dplyr.tidyverse.org/reference/tbl_df.html). The
column names include `Subject`, `Iso_type`, `t`, and `result`.

## Usage

``` r
use_att_names(data)
```

## Arguments

- data:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) raw
  longitudinal data that has been prepared for antibody kinetic modeling
  using
  [`as_case_data()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/as_case_data.md).

## Value

The input [data.frame](https://rdrr.io/r/base/data.frame.html) with
columns named after attributes.
