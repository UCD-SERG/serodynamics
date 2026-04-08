# Default print for [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr114/reference/run_mod.md) output object of class `sr_model`

A default print method for class `sr_model` that includes the median
predictive posterior distribution for antibody kinetic curve parameters
by `Iso_type` and `Stratification` (if specified).

## Usage

``` r
# S3 method for class 'sr_model'
print(x, print_tbl = FALSE, ...)
```

## Arguments

- x:

  An `sr_model` output object from
  [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr114/reference/run_mod.md).

- print_tbl:

  A [logical](https://rdrr.io/r/base/logical.html) indicator to print in
  style of
  [dplyr::tbl_df](https://dplyr.tidyverse.org/reference/defunct.html).

- ...:

  Additional arguments affecting the summary produced.
  [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr114/reference/run_mod.md)
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
#>   Stratification Iso_type       alpha    shape       t1       y0       y1
#> 1          typhi HlyE_IgA 0.001508265 1.673340 6.358405 2.340330 258.1235
#> 2      paratyphi HlyE_IgA 0.001556295 1.561960 3.903690 2.852925 191.8805
#> 3          typhi HlyE_IgG 0.001393980 1.385280 6.019110 1.788035 243.9110
#> 4      paratyphi HlyE_IgG 0.001432405 1.386685 4.726980 2.330555 272.8455
```
