# Append Model 2a factor priors to a Chapter 1 prior list

Model 2a reuses every Chapter 1 hyperprior unchanged and adds only two
extra inputs needed by `model_2a.jags`:

- `prec.lambda`: the prior precision (1 / variance) of the factor
  loadings `lambda[k, p]`. Smaller values are more diffuse (allow larger
  cross-biomarker covariances).

- `zero_p`: a length-`n_params` vector of zeros (the mean of the
  within-biomarker random effects `w`).

Keeping this as its own one-job function makes it easy to test and to
see exactly what Model 2a adds on top of Chapter 1.

## Usage

``` r
add_factor_priors(priors, prec_lambda = 0.25)
```

## Arguments

- priors:

  A `curve_params_priors` list from
  [`prep_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors.md).

- prec_lambda:

  A positive [numeric](https://rdrr.io/r/base/numeric.html) scalar:
  prior precision of the loadings. Default `0.25` (loading SD = 2),
  weakly informative.

## Value

The input list with `prec.lambda` and `zero_p` added.
