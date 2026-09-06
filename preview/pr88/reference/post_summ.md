# Summary Table of Jags Posterior Estimates

`post_summ()` takes a [list](https://rdrr.io/r/base/list.html) output
from
[`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr88/reference/run_mod.md)
to summary table for parameter, antigen/antibody, and stratification
combination. Defaults will produce every combination of
antigen/antibody, parameters, and stratifications, unless otherwise
specified. Antigen/antibody combinations and stratifications will vary
by analysis. The antibody dynamic curve includes the following
parameters:

- y0 = baseline antibody concentration

- y1 = peak antibody concentration

- t1 = time to peak

- r = shape parameter

- alpha = decay rate

## Usage

``` r
post_summ(
  data,
  iso = unique(data$curve_params$Iso_type),
  param = unique(data$curve_params$Parameter_sub),
  strat = unique(data$curve_params$Stratification)
)
```

## Arguments

- data:

  A [list](https://rdrr.io/r/base/list.html) outputted from
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr88/reference/run_mod.md).

- iso:

  Specify [character](https://rdrr.io/r/base/character.html) string to
  produce tables of only a specific antigen/antibody combination,
  entered with quotes. Default outputs all antigen/antibody
  combinations.

- param:

  Specify [character](https://rdrr.io/r/base/character.html) string to
  produce tables of only a specific parameter, entered with quotes.
  Options include:

  - `alpha` = posterior estimate of decay rate

  - `r` = posterior estimate of shape parameter

  - `t1` = posterior estimate of time to peak

  - `y0` = posterior estimate of baseline antibody concentration

  - `y1` = posterior estimate of peak antibody concentration

- strat:

  Specify [character](https://rdrr.io/r/base/character.html) string to
  produce tables of specific stratification entered in quotes.

## Value

A [data.frame](https://rdrr.io/r/base/data.frame.html) summarizing
estimate mean, standard deviation (SD), median, and quantiles (2.5%,
25.0%, 50.0%, 75.0%, 97.5%).

## Author

Sam Schildhauer

## Examples

``` r
post_summ(data = serodynamics::nepal_sees_jags_output)
#> # A tibble: 20 × 11
#>    Iso_type Parameter_sub Stratification    Mean      SD  Median  `2.5%` `25.0%`
#>    <chr>    <chr>         <chr>            <dbl>   <dbl>   <dbl>   <dbl>   <dbl>
#>  1 HlyE_IgA alpha         paratyphi      2.29e-3 3.75e-3 1.27e-3 1.11e-4 5.79e-4
#>  2 HlyE_IgA alpha         typhi          3.78e-3 6.16e-3 2.17e-3 3.08e-4 1.12e-3
#>  3 HlyE_IgA shape         paratyphi      1.66e+0 2.74e-1 1.61e+0 1.29e+0 1.47e+0
#>  4 HlyE_IgA shape         typhi          1.65e+0 3.68e-1 1.57e+0 1.23e+0 1.42e+0
#>  5 HlyE_IgA t1            paratyphi      3.85e+0 1.34e+0 3.70e+0 1.86e+0 2.92e+0
#>  6 HlyE_IgA t1            typhi          7.62e+0 4.83e+0 6.67e+0 2.26e+0 4.61e+0
#>  7 HlyE_IgA y0            paratyphi      2.55e+0 9.07e-1 2.41e+0 1.23e+0 1.87e+0
#>  8 HlyE_IgA y0            typhi          2.90e+0 2.92e+0 2.25e+0 5.76e-1 1.52e+0
#>  9 HlyE_IgA y1            paratyphi      1.02e+3 6.84e+3 1.54e+2 8.85e+0 5.45e+1
#> 10 HlyE_IgA y1            typhi          1.73e+3 7.50e+3 2.69e+2 8.41e+0 9.10e+1
#> 11 HlyE_IgG alpha         paratyphi      2.57e-3 2.60e-3 1.74e-3 2.29e-4 8.76e-4
#> 12 HlyE_IgG alpha         typhi          1.75e-3 1.69e-3 1.22e-3 2.38e-4 7.06e-4
#> 13 HlyE_IgG shape         paratyphi      1.36e+0 2.03e-1 1.32e+0 1.10e+0 1.19e+0
#> 14 HlyE_IgG shape         typhi          1.52e+0 3.88e-1 1.42e+0 1.11e+0 1.27e+0
#> 15 HlyE_IgG t1            paratyphi      4.78e+0 2.09e+0 4.37e+0 1.93e+0 3.30e+0
#> 16 HlyE_IgG t1            typhi          9.76e+0 8.02e+0 7.67e+0 1.87e+0 4.59e+0
#> 17 HlyE_IgG y0            paratyphi      1.72e+0 7.66e-1 1.54e+0 7.09e-1 1.19e+0
#> 18 HlyE_IgG y0            typhi          2.29e+0 1.94e+0 1.82e+0 3.80e-1 1.09e+0
#> 19 HlyE_IgG y1            paratyphi      8.33e+2 2.13e+3 2.88e+2 1.82e+1 1.09e+2
#> 20 HlyE_IgG y1            typhi          4.02e+2 6.91e+2 2.21e+2 3.02e+1 1.07e+2
#> # ℹ 3 more variables: `50.0%` <dbl>, `75.0%` <dbl>, `97.5%` <dbl>
```
