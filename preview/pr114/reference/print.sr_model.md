# Default print for [`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr114/reference/run_mod.md) output object of class `sr_model`

A default print method for class `sr_model` that includes the median
posterior distribution for antibody kinetic curve parameters by
`Iso_type` and `Stratification` (if specified).

## Usage

``` r
# S3 method for class 'sr_model'
print(x, print_tbl = FALSE, ...)
```

## Arguments

- x:

  An `sr_model` output object from
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr114/reference/run_mod.md).

- print_tbl:

  A [logical](https://rdrr.io/r/base/logical.html) indicator to print in
  style of
  [dplyr::tbl_df](https://dplyr.tidyverse.org/reference/tbl_df.html).

- ...:

  Additional arguments affecting the summary produced.
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr114/reference/run_mod.md)
  function.

## Value

A data summary that contains the median posterior distribution for
antibody kinetic curve parameters by `Iso_type` and `Stratification` (if
specified).

## Examples

``` r
print(nepal_sees_jags_output)
#> An sr_model with the following median values:
#> 
#>   Stratification Iso_type       alpha    shape      t1       y0       y1
#> 1          typhi HlyE_IgA 0.000869201 1.587970 6.41418 2.486935 317.1110
#> 2      paratyphi HlyE_IgA 0.001556295 1.561960 3.90369 2.852925 191.8805
#> 3          typhi HlyE_IgG 0.001337480 1.304980 5.88293 1.805900 297.7720
#> 4      paratyphi HlyE_IgG 0.001432405 1.386685 4.72698 2.330555 272.8455
```
