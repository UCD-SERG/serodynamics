# Compare Chapter 1 and Model 2a on the same data

Fits **both** the Chapter 1 model
([`fit_chapter1_lean()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/fit_chapter1_lean.md),
the same posterior as
[`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod.md))
and **Model 2a**
([`run_mod_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod_2a.md))
to the same data, then reports:

1.  **What stays the same** — the shared population means `mu.par` and
    the within-biomarker variances, side by side, with absolute
    differences. Because Model 2a strictly nests Chapter 1, these should
    agree within MCMC error; large differences would signal a problem.

2.  **What Model 2a adds** — the cross-biomarker covariance `c_p` /
    correlation `rho_p`, which Chapter 1 cannot represent (it is
    structurally zero there).

Use this to answer "what changed when I added cross-biomarker
covariance?".

**On "what improved".** A point-estimate comparison shows *consistency
plus the new term*; it does not by itself establish that Model 2a is
*better*. A rigorous improvement claim needs a model-selection criterion
(DIC/WAIC; set `dic = TRUE` for a best-effort DIC from each `runjags`
fit) and, ultimately, the downstream predictive task (e.g.
time-since-infection / seroincidence accuracy — MAE, RMSE, CrI
coverage), which is the Chapter 2 simulation study rather than a single
function.

## Usage

``` r
compare_mod_2a(
  data,
  nchain = 4,
  nadapt = 1000,
  nburn = 1000,
  nmc = 1000,
  niter = 4000,
  prec_lambda = 0.25,
  dic = FALSE,
  ...
)
```

## Arguments

- data:

  A two-biomarker `serocalculator` case-data
  [data.frame](https://rdrr.io/r/base/data.frame.html) (e.g.
  `nepal_sees`).

- nchain, nadapt, nburn, nmc, niter:

  MCMC controls applied to **both** fits.

- prec_lambda:

  Factor-loading prior precision (Model 2a only).

- dic:

  [logical](https://rdrr.io/r/base/logical.html); attempt to extract DIC
  from each `runjags` fit (best-effort; may re-run the models and can be
  slow). Default `FALSE`.

- ...:

  Prior arguments forwarded to **both**
  [`prep_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors.md)
  and
  [`prep_priors_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors_2a.md).

## Value

A list of class `"model_2a_comparison"` with:

- `shared`: [data.frame](https://rdrr.io/r/base/data.frame.html)
  comparing `mean`/`var` per biomarker x parameter (`*_ch1`, `*_2a`, and
  `*_absdiff`);

- `cross`: Model 2a's cross-biomarker covariance/correlation summary;

- `max_mean_absdiff`, `max_var_absdiff`: worst-case shared-parameter
  discrepancies (small = consistent);

- `added`: the parameters whose `c_p` credible interval excludes zero;

- `dic_ch1`, `dic_2a`: raw DIC objects when `dic = TRUE` (else `NULL`);

- `fits`: the two underlying fit objects.
