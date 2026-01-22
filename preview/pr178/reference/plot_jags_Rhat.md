# Rhat Plot Diagnostics

plot_jags_Rhat() takes a [list](https://rdrr.io/r/base/list.html) output
from
[`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr178/reference/run_mod.md)
to produce dotplots of potential scale reduction factors (Rhat) for each
chain run in the mcmc estimation. Rhat values analyze the spread of
chains compared to pooled values with a goal of observing rhat \< 1.10
for convergence. Defaults will produce every combination of
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
plot_jags_Rhat(
  data,
  iso = unique(data$Iso_type),
  param = unique(data$Parameter),
  strat = unique(data$Stratification)
)
```

## Arguments

- data:

  A [list](https://rdrr.io/r/base/list.html) outputted from run_mod().

- iso:

  Specify [character](https://rdrr.io/r/base/character.html) string to
  produce plots of only a specific antigen/antibody combination, entered
  with quotes. Default outputs all antigen/antibody combinations.

- param:

  Specify [character](https://rdrr.io/r/base/character.html) string to
  produce plots of only a specific parameter, entered with quotes.
  Options include:

  - `y0` = posterior estimate of baseline antibody concentration

  - `y1` = posterior estimate of peak antibody concentration

  - `t1` = posterior estimate of time to peak

  - `r` = posterior estimate of shape parameter

  - `alpha` = posterior estimate of decay rate

- strat:

  Specify [character](https://rdrr.io/r/base/character.html) string to
  produce plots of specific stratification entered in quotes.

## Value

A [list](https://rdrr.io/r/base/list.html) of
[ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
objects producing dotplots with rhat values for all the specified input.

## Author

Sam Schildhauer

## Examples

``` r
data <- serodynamics::nepal_sees_jags_output

plot_jags_Rhat(data = data,
               iso = "HlyE_IgA",
               strat = "typhi")
```
