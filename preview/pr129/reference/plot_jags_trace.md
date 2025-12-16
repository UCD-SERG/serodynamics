# Trace Plot Diagnostics

plot_jags_trace() takes a [list](https://rdrr.io/r/base/list.html)
output from
[`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr129/reference/run_mod.md)
to create trace plots for each chain run in the mcmc estimation.
Defaults will produce every combination of antigen/antibody, parameters,
and stratifications, unless otherwise specified. Antigen/antibody
combinations and stratifications will vary by analysis. The antibody
dynamic curve includes the following parameters:

- y0 = baseline antibody concentration

- y1 = peak antibody concentration

- t1 = time to peak

- r = shape parameter

- alpha = decay rate

## Usage

``` r
plot_jags_trace(
  data,
  iso = unique(data$Iso_type),
  param = unique(data$Parameter),
  strat = unique(data$Stratification)
)
```

## Arguments

- data:

  A [list](https://rdrr.io/r/base/list.html) outputted from
  [`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr129/reference/run_mod.md).

- iso:

  Specify [character](https://rdrr.io/r/base/character.html) string to
  produce plots of only a specific antigen/antibody combination, entered
  with quotes. Default outputs all antigen/antibody combinations.

- param:

  Specify [character](https://rdrr.io/r/base/character.html) string to
  produce plots of only a specific parameter, entered with quotes.
  Options include:

  - `alpha` = posterior estimate of decay rate

  - `r` = posterior estimate of shape parameter

  - `t1` = posterior estimate of time to peak

  - `y0` = posterior estimate of baseline antibody concentration

  - `y1` = posterior estimate of peak antibody concentration

- strat:

  Specify [character](https://rdrr.io/r/base/character.html) string to
  produce plots of specific stratification entered in quotes.

## Value

A [list](https://rdrr.io/r/base/list.html) of
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
objects producing trace plots for all the specified input.

## Author

Sam Schildhauer

## Examples

``` r
data <- serodynamics::nepal_sees_jags_output

# Specifying isotype, parameter, and stratification for traceplot.
plot_jags_trace(
                data = data,
                iso = "HlyE_IgA",
                strat = "typhi")
```
