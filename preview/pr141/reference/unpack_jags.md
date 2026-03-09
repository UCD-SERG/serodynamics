# Unpacking MCMC Object

`unpack_jags()` takes a long-format MCMC sample (typically created by
applying [`ggmcmc::ggs()`](https://rdrr.io/pkg/ggmcmc/man/ggs.html) to
the `mcmc` component of
[`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr141/reference/run_mod.md)
output) and unpacks it correctly for all population parameters.

## Usage

``` r
unpack_jags(data)
```

## Arguments

- data:

  A
  [`dplyr::tbl_df()`](https://dplyr.tidyverse.org/reference/defunct.html)
  in [`ggmcmc::ggs()`](https://rdrr.io/pkg/ggmcmc/man/ggs.html) /
  MCMC-long format, usually `ggmcmc::ggs(jags_post[["mcmc"]])` where
  `jags_post` comes from
  [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr141/reference/run_mod.md).
  Must contain at least `Iteration`, `Chain`, `Parameter`, and `value`
  columns.

## Value

A
[`dplyr::tbl_df()`](https://dplyr.tidyverse.org/reference/defunct.html)
that contains MCMC samples from the joint posterior distribution of the
model with unpacked parameters, isotypes, and subjects.

## Author

Sam Schildhauer
