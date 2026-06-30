# Unpacking MCMC Object

`unpack_jags()` takes a long-format MCMC sample (typically created by
applying [`ggmcmc::ggs()`](https://rdrr.io/pkg/ggmcmc/man/ggs.html) to
the `mcmc` component of
[run_serodynamics](https:/ucd-serg.github.io/serodynamics/preview/pr252/reference/run_serodynamics.md)
output) and unpacks it into separate rows for individual-level curve
parameters and population-level hyperparameters/precision terms.

## Usage

``` r
unpack_jags(data)
```

## Arguments

- data:

  A
  [tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
  in [`ggmcmc::ggs()`](https://rdrr.io/pkg/ggmcmc/man/ggs.html) /
  MCMC-long format, usually `ggmcmc::ggs(jags_post[["mcmc"]])` where
  `jags_post` comes from
  [run_serodynamics](https:/ucd-serg.github.io/serodynamics/preview/pr252/reference/run_serodynamics.md).
  Must contain at least `Iteration`, `Chain`, `Parameter`, and `value`
  columns.

## Value

A
[tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
containing MCMC samples from the joint posterior distribution of the
model with unpacked individual-level parameters (e.g., `y0`, `y1`, `t1`,
`alpha`, `shape`) and population-level parameters (e.g., `mu.par`,
`prec.par`, `prec.logy`), along with subject-related fields such as
`Subject` and `Subnum`. Isotype names are not added by `unpack_jags()`
itself.

## Author

Sam Schildhauer
