# Lean Chapter 1 fit (for comparison with Model 2a)

Fits the **Chapter 1** model (`model.jags`) through the same lean path
as
[`run_mod_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod_2a.md)
and returns the raw `runjags` object, monitoring the nodes needed to
compare against Model 2a (`mu.par`, `prec.par`). This is the **same
model, data, priors, and posterior** as
[`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod.md)
—
[`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod.md)
simply adds post-processing on top; here we keep the MCMC in `mcmc.list`
form so it can be compared directly with a Model 2a fit.

Unstratified only (matching the typhoid example workflow).

## Usage

``` r
fit_chapter1_lean(
  data,
  file_mod = serodynamics_example("model.jags"),
  nchain = 4,
  nadapt = 1000,
  nburn = 1000,
  nmc = 1000,
  niter = 4000,
  ...
)
```

## Arguments

- data:

  A `serocalculator` case-data
  [data.frame](https://rdrr.io/r/base/data.frame.html).

- file_mod:

  Path to the Chapter 1 JAGS model (defaults to the packaged
  `model.jags`).

- nchain, nadapt, nburn, nmc, niter:

  MCMC controls (as in
  [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod.md)).

- ...:

  Prior arguments forwarded to
  [`prep_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors.md).

## Value

A `runjags` object (its `$mcmc` is a
[coda::mcmc.list](https://rdrr.io/pkg/coda/man/mcmc.list.html)).
