# Fit Model 2a (Chapter 1 + alpha) with JAGS

Fits the Model 2a extension of `model.jags`. Model 2a keeps Chapter 1's
within-biomarker covariance blocks intact (`Sigma_G`, `Sigma_A` via the
same Wishart prior) and adds same-parameter cross-biomarker covariances
through a shared latent factor per kinetic parameter: \$\$par\_{i,k,p} =
\mu\_{k,p} + w\_{i,k,p} + \lambda\_{k,p}\\ f\_{i,p},\$\$ so that for two
biomarkers the cross-biomarker covariance is \\c_p =
\lambda\_{1,p}\lambda\_{2,p}\\ and Chapter 1 is recovered exactly when
all `lambda = 0`.

This wrapper is intentionally lean and decomposed: it builds the JAGS
input
([`jags_data_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/jags_data_2a.md)),
runs the sampler, and returns the raw MCMC plus a tidy cross-biomarker
summary
([`summarize_cross_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/summarize_cross_2a.md)).
It does **not** reproduce the full `sr_model` post-processing of
[`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod.md);
the goal is a small, debuggable object focused on the Chapter 2
covariance question.

## Usage

``` r
run_mod_2a(
  data,
  file_mod = serodynamics_example("model_2a.jags"),
  nchain = 4,
  nadapt = 1000,
  nburn = 1000,
  nmc = 1000,
  niter = 4000,
  prec_lambda = 0.25,
  extra_monitors = NULL,
  ...
)
```

## Arguments

- data:

  A `serocalculator` case-data
  [data.frame](https://rdrr.io/r/base/data.frame.html) with **two**
  biomarkers (e.g. `HlyE_IgG` / `HlyE_IgA`).

- file_mod:

  Path to the Model 2a JAGS file. Defaults to the packaged
  `model_2a.jags`.

- nchain, nadapt, nburn, nmc, niter:

  Standard MCMC controls, matching
  [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod.md)
  (chains, adaptation, burn-in, samples kept, total iterations).

- prec_lambda:

  Prior precision of the factor loadings. Default `0.25`.

- extra_monitors:

  Optional [character](https://rdrr.io/r/base/character.html) vector of
  additional nodes to monitor (e.g. `"y0"`). The covariance machinery
  always monitors `lambda`, `mu.par`, `prec.par`, and `prec.logy`.

- ...:

  Additional Chapter 1 prior arguments forwarded to
  [`prep_priors_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors_2a.md).

## Value

A list of class `"model_2a_fit"` with elements:

- `mcmc`: the
  [coda::mcmc.list](https://rdrr.io/pkg/coda/man/mcmc.list.html) of
  posterior draws;

- `cross`: a tidy [data.frame](https://rdrr.io/r/base/data.frame.html)
  of posterior cross-biomarker covariance `c_p` and correlation `rho_p`
  per kinetic parameter;

- `antigens`: the two biomarker labels;

- `prec_lambda`: the loading-prior precision used;

- `runjags`: the raw `runjags` object (for diagnostics such as PSRF).

## Author

Kwan Ho Lee

## Examples

``` r
# Model 2a (Chapter 1 + alpha) -- example usage.
# Mirrors run_mod-examples.R: one representative fit when JAGS is available.
# Heavier validation / comparison calls are shown commented out (run locally).
if (!is.element(runjags::findjags(), c("", NULL))) {
  library(serodynamics)

  # nepal_sees ships as `case_data` with exactly two biomarkers:
  # HlyE_IgG and HlyE_IgA. It is already in the right format -- pass it directly.
  data(nepal_sees)

  fit <- run_mod_2a(
    data = nepal_sees,
    file_mod = serodynamics_example("model_2a.jags"),
    nchain = 4, nadapt = 100, nburn = 100, nmc = 1000, niter = 2000
  )

  # cross-biomarker (IgG ~ IgA) covariance & correlation, per kinetic parameter
  print(fit$cross)

  # ---- run these locally (Mercury) at full length; omitted from routine check:
  # validate_recovery_2a()                  # recover a known correlation
  # validate_nesting_2a()                   # ~0 when there is none
  # cmp <- compare_mod_2a(nepal_sees)       # Chapter 1 vs Model 2a
  # print(cmp$shared); print(cmp$added)     # shared params + the addition
}
#> Calling 4 simulations using the parallel method...
#> Following the progress of chain 1 (the program will wait for all chains
#> to finish before continuing):
#> Welcome to JAGS 4.3.2 on Sat Jun 20 22:01:22 2026
#> JAGS is free software and comes with ABSOLUTELY NO WARRANTY
#> Loading module: basemod: ok
#> Loading module: bugs: ok
#> . . Reading data file data.txt
#> . Compiling model graph
#>    Resolving undeclared variables
#>    Allocating nodes
#> Graph information:
#>    Observed stochastic nodes: 904
#>    Unobserved stochastic nodes: 1455
#>    Total graph size: 24084
#> . Reading parameter file inits1.txt
#> . Initializing model
#> . Adapting 100
#> -------------------------------------------------| 100
#> ++++++++++++++++++++++++++++++++++++++++++++++++++ 100%
#> Adaptation incomplete.
#> . Updating 100
#> -------------------------------------------------| 100
#> ************************************************** 100%
#> . . . . . Updating 2000
#> -------------------------------------------------| 2000
#> ************************************************** 100%
#> . . . . Updating 0
#> . Deleting model
#> . 
#> All chains have finished
#> Warning: The adaptation phase of one or more models was not completed in 100 iterations, so the current samples may not be optimal - try increasing the number of iterations to the "adapt" argument
#> Simulation complete.  Reading coda files...
#> Coda files loaded successfully
#> Finished running the simulation
#>               param                pair   cov_med       cov_lo   cov_hi
#> 1            log_y0 HlyE_IgA ~ HlyE_IgG 0.9934949 -2.067011394 6.675816
#> 2   log_y1_minus_y0 HlyE_IgA ~ HlyE_IgG 4.0231980 -0.066421122 6.658893
#> 3            log_t1 HlyE_IgA ~ HlyE_IgG 0.1138932 -0.415686196 1.284705
#> 4         log_alpha HlyE_IgA ~ HlyE_IgG 2.8116716 -0.050777306 8.022045
#> 5 log_shape_minus_1 HlyE_IgA ~ HlyE_IgG 0.2666201 -0.001784248 1.098064
#>     cor_med      cor_lo    cor_hi
#> 1 0.4782625 -0.95238714 0.9915772
#> 2 0.7236680 -0.04940564 0.8617331
#> 3 0.1892707 -0.64416555 0.9310668
#> 4 0.8293360 -0.10192191 0.9480339
#> 5 0.8314297 -0.03564527 0.9438603
```
