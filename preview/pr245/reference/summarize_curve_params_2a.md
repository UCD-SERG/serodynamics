# Summarize shared curve-parameter posteriors

Extracts the quantities that Chapter 1 (`model.jags`) and Model 2a
(`model_2a.jags`) have in **common** so they can be compared directly:
the population means `mu.par[k, p]` and the within-biomarker variances.
For Model 2a the within-biomarker variance is the *marginal* variance
`diag(solve(prec.par[k])) + lambda[k, ]^2` (set `with_loadings = TRUE`);
for Chapter 1 there are no loadings, so it is just
`diag(solve(prec.par[k]))` (`with_loadings = FALSE`). Posterior medians
are returned.

Pure extraction/summary (delegates the variance algebra to
[`marginal_var_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/marginal_var_2a.md));
no fitting.

## Usage

``` r
summarize_curve_params_2a(mcmc, with_loadings = FALSE, param_names = NULL)
```

## Arguments

- mcmc:

  A [coda::mcmc.list](https://rdrr.io/pkg/coda/man/mcmc.list.html) (or a
  named draws [matrix](https://rdrr.io/r/base/matrix.html)) containing
  monitored `mu.par` and `prec.par` (and `lambda` when `with_loadings`).

- with_loadings:

  [logical](https://rdrr.io/r/base/logical.html); add the squared factor
  loadings to the within-biomarker variance (TRUE for Model 2a, FALSE
  for Chapter 1).

- param_names:

  Optional length-`P` parameter labels (defaults to the log-scale
  names).

## Value

A [data.frame](https://rdrr.io/r/base/data.frame.html) with columns
`biomarker` (index), `param`, `mean_med` (median of `mu.par`), and
`var_med` (median within-biomarker variance).
