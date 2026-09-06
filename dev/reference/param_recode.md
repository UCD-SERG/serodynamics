# Parameter recode

`param_recode()` recodes JAGS curve-parameter indices (1-5) as their
log-scale parameter labels (e.g., `"log(y0)"`, `"log(alpha)"`).

## Usage

``` r
param_recode(x)
```

## Arguments

- x:

  A [vector](https://rdrr.io/r/base/vector.html) of character numbers
  ("1"-"5") that represent parameters.

## Value

A [vector](https://rdrr.io/r/base/vector.html) of log-scale parameter
labels.

## Author

Sam Schildhauer
