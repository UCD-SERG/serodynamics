# Summary Table of Jags Posterior Estimates

`post_summ()` takes a [list](https://rdrr.io/r/base/list.html) output
from
[`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr141/reference/run_mod.md)
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
  iso = unique(data$Iso_type),
  param = unique(data$Parameter),
  strat = unique(data$Stratification)
)
```

## Arguments

- data:

  A [list](https://rdrr.io/r/base/list.html) outputted from
  [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr141/reference/run_mod.md).

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
#>    Iso_type Parameter Stratification       Mean       SD  Median  `2.5%` `25.0%`
#>    <chr>    <chr>     <chr>               <dbl>    <dbl>   <dbl>   <dbl>   <dbl>
#>  1 HlyE_IgA alpha     paratyphi         0.00266  3.92e-3 1.56e-3 1.99e-4 7.47e-4
#>  2 HlyE_IgA alpha     typhi             0.00293  4.18e-3 1.51e-3 1.48e-4 6.88e-4
#>  3 HlyE_IgA shape     paratyphi         1.63     2.82e-1 1.56e+0 1.27e+0 1.44e+0
#>  4 HlyE_IgA shape     typhi             1.77     4.41e-1 1.67e+0 1.26e+0 1.49e+0
#>  5 HlyE_IgA t1        paratyphi         4.28     2.11e+0 3.90e+0 1.56e+0 2.73e+0
#>  6 HlyE_IgA t1        typhi             7.91     5.98e+0 6.36e+0 1.95e+0 4.39e+0
#>  7 HlyE_IgA y0        paratyphi         3.83     2.65e+0 2.85e+0 1.07e+0 1.88e+0
#>  8 HlyE_IgA y0        typhi             2.90     2.23e+0 2.34e+0 7.70e-1 1.69e+0
#>  9 HlyE_IgA y1        paratyphi      2781.       4.19e+4 1.92e+2 7.45e+0 5.61e+1
#> 10 HlyE_IgA y1        typhi          1275.       6.42e+3 2.58e+2 9.11e+0 8.44e+1
#> 11 HlyE_IgG alpha     paratyphi         0.00202  2.11e-3 1.43e-3 2.25e-4 7.07e-4
#> 12 HlyE_IgG alpha     typhi             0.00196  1.88e-3 1.39e-3 2.69e-4 7.57e-4
#> 13 HlyE_IgG shape     paratyphi         1.41     1.56e-1 1.39e+0 1.17e+0 1.29e+0
#> 14 HlyE_IgG shape     typhi             1.49     3.78e-1 1.39e+0 1.08e+0 1.23e+0
#> 15 HlyE_IgG t1        paratyphi         5.02     1.87e+0 4.73e+0 2.18e+0 3.75e+0
#> 16 HlyE_IgG t1        typhi             7.67     6.84e+0 6.02e+0 1.59e+0 3.82e+0
#> 17 HlyE_IgG y0        paratyphi         2.46     9.14e-1 2.33e+0 1.23e+0 1.87e+0
#> 18 HlyE_IgG y0        typhi             2.11     1.40e+0 1.79e+0 4.79e-1 1.22e+0
#> 19 HlyE_IgG y1        paratyphi       929.       4.52e+3 2.73e+2 2.09e+1 1.08e+2
#> 20 HlyE_IgG y1        typhi           512.       9.65e+2 2.44e+2 2.77e+1 1.11e+2
#> # ℹ 3 more variables: `50.0%` <dbl>, `75.0%` <dbl>, `97.5%` <dbl>
```
