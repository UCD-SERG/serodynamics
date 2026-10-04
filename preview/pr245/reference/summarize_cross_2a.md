# Summarize cross-biomarker covariance from a Model 2a fit

Reads posterior draws of the loadings (`lambda`) and within-biomarker
precisions (`prec.par`) from a Model 2a `mcmc.list` and returns, per
kinetic parameter, the posterior median and 95% credible interval of:

- `c_p` = same-parameter cross-biomarker covariance
  (\\\lambda\_{1,p}\lambda\_{2,p}\\);

- `rho_p` = the corresponding cross-biomarker correlation.

The per-draw algebra is delegated to the small pure helpers
[`cross_cov_from_loadings()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/cross_cov_from_loadings.md)
and
[`cross_cor_from_draw_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/cross_cor_from_draw_2a.md),
so this function only handles extraction and summarization.

## Usage

``` r
summarize_cross_2a(
  mcmc,
  antigens = NULL,
  param_names = NULL,
  probs = c(0.025, 0.5, 0.975)
)
```

## Arguments

- mcmc:

  A [coda::mcmc.list](https://rdrr.io/pkg/coda/man/mcmc.list.html) from
  [`run_mod_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod_2a.md)
  (must contain monitored `lambda` and `prec.par` nodes).

- antigens:

  Optional length-2 [character](https://rdrr.io/r/base/character.html)
  vector of biomarker labels, used only for the printed pair label.

- param_names:

  Optional length-`P` [character](https://rdrr.io/r/base/character.html)
  vector of kinetic parameter names. Defaults to the log-scale names.

- probs:

  Quantiles for the credible interval. Default `c(0.025, 0.5, 0.975)`.

## Value

A [data.frame](https://rdrr.io/r/base/data.frame.html) with one row per
kinetic parameter and columns `param`, `pair`, `cov_med`, `cov_lo`,
`cov_hi`, `cor_med`, `cor_lo`, `cor_hi`.
