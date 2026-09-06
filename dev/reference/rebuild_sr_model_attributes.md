# Rebuild `sr_model` output attributes in a stable order

`rebuild_sr_model_attributes()` reconstructs the attribute list of the
combined
[`run_serodynamics()`](https://ucd-serg.github.io/serodynamics/dev/reference/run_serodynamics.md)
output in a fixed order, ensuring `class` appears immediately after
`names` and `row.names`. The `dplyr` operations used to assemble the
output can carry `ggmcmc` attributes (`nChains`, etc.) into the result
and push `class` to the end, so this helper rebuilds the attributes
explicitly. `mod_atts` (a named selection from the
[`ggmcmc::ggs()`](https://rdrr.io/pkg/ggmcmc/man/ggs.html) object) is
the authoritative source for the `ggmcmc`-style metadata attributes.

## Usage

``` r
rebuild_sr_model_attributes(x, mod_atts)
```

## Arguments

- x:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) /
  [tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
  of combined MCMC output.

- mod_atts:

  A named [list](https://rdrr.io/r/base/list.html) of `ggmcmc` metadata
  attributes, containing `nChains`, `nParameters`, `nIterations`,
  `nBurnin`, and `nThin`.

## Value

`x` with its attributes rebuilt in a stable order and the `sr_model`
class prepended.

## Author

Sam Schildhauer
