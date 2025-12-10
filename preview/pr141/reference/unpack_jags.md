# Unpacking MCMC Object

`jags_unpack()` takes an MCMC output from run_mod and unpacks it
correctly including for all population parameters.

## Usage

``` r
unpack_jags(data)
```

## Arguments

- data:

  A
  [`dplyr::tbl_df()`](https://dplyr.tidyverse.org/reference/tbl_df.html)
  output object from run_mod

## Value

An
[`dplyr::tbl_df()`](https://dplyr.tidyverse.org/reference/tbl_df.html)
that contains MCMC samples from the joint posterior distribution of the
model with unpacked parameters, isotypes, and subjects.

## Author

Sam Schildhauer
