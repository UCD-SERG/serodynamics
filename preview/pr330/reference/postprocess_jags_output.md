# Postprocess JAGS output

Postprocess JAGS output

## Usage

``` r
postprocess_jags_output(jags_output, ids, antigen_isos)
```

## Arguments

- jags_output:

  output from
  [`runjags::run.jags()`](https://rdrr.io/pkg/runjags/man/run.jags.html)

- ids:

  IDs of individuals being sampled (JAGS discards this information, so
  it has to be re-attached)

- antigen_isos:

  names of biomarkers being modeled (JAGS discards this information, so
  it has to be re-attached)

## Value

a
[tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)

## Examples

``` r
set.seed(1)
raw_data <-
  serocalculator::typhoid_curves_nostrat_100 |>
  dplyr::filter(
    antigen_iso |> stringr::str_starts(pattern = "HlyE")
  ) |>
  sim_case_data(
    n = 5,
    antigen_isos = c("HlyE_IgA", "HlyE_IgG")
  )
prepped_data <- prep_data(raw_data)
priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos,
                      mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
                      prec_hyp_param = c(1.0, 0.0001, 1.0, 0.001, 1.0),
                      omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
                      wishdf_param = 20,
                      prec_logy_hyp_param = c(4.0, 1.0))
nchains <- 2
# nr of MC chains to run simultaneously
nadapt <- 100
# nr of iterations for adaptation
nburnin <- 100
# nr of iterations to use for burn-in
nmc <- 100
# nr of samples in posterior chains
niter <- 100
# nr of iterations for posterior sample
nthin <- round(niter / nmc)
# thinning needed to produce nmc from niter

tomonitor <- c("y0", "y1", "t1", "alpha", "shape")

file_mod <- serodynamics_example("model.jags")

set.seed(11325)
jags_post <- runjags::run.jags(
  model = file_mod,
  data = c(prepped_data, priors),
  inits = initsfunction,
  method = "parallel",
  adapt = nadapt,
  burnin = nburnin,
  thin = nthin,
  sample = nmc,
  n.chains = nchains,
  monitor = tomonitor,
  summarise = FALSE
)
#> Calling 2 simulations using the parallel method...
#> Following the progress of chain 1 (the program will wait for all chains
#> to finish before continuing):
#> Welcome to JAGS 5.0.2 on Wed Nov 25 00:54:36 2026
#> JAGS is free software and comes with ABSOLUTELY NO WARRANTY
#> Loading module: basemod: ok
#> Loading module: bugs: ok
#> Loading module: diag: ok
#> . . Reading data file data.txt
#> . Compiling model graph
#>    Resolving undeclared variables
#>    Allocating nodes
#> Graph information:
#>    Fully observed stochastic nodes: 42
#>    Unobserved stochastic nodes: 24
#>    Total graph size: 930
#> . Reading parameter file inits1.txt
#> . Initializing model
#> . Adaptation skipped: model is not in adaptive mode.
#> . Updating 100
#> -------------------------------------------------| 100
#> ************************************************** 100%
#> . . . . . . Updating 100
#> -------------------------------------------------| 100
#> ************************************************** 100%
#> . . . . Updating 0
#> . Deleting model
#> . Exiting JAGS
#> All chains have finished
#> Note: the model did not require adaptation
#> Simulation complete.  Reading coda files...
#> Coda files loaded successfully
#> Finished running the simulation

curve_params <- jags_post |> postprocess_jags_output(
  ids = attr(prepped_data, "ids"),
  antigen_isos = attr(prepped_data, "antigens")
)

print(curve_params)
#> # A tibble: 400 × 8
#>    antigen_iso  iter chain    y0     y1    t1      alpha     r
#>    <fct>       <int> <int> <dbl>  <dbl> <dbl>      <dbl> <dbl>
#>  1 HlyE_IgA        1     1 1.15   91.5  0.459 0.000463    1.03
#>  2 HlyE_IgA        2     1 0.873  97.2  0.678 0.0000723   1.03
#>  3 HlyE_IgA        3     1 1.18    5.57 0.633 0.000128    1.05
#>  4 HlyE_IgA        4     1 0.838   3.17 0.813 0.0000904   1.06
#>  5 HlyE_IgA        5     1 1.38    5.05 0.545 0.0000639   1.04
#>  6 HlyE_IgA        6     1 0.762   6.58 0.876 0.0000226   1.06
#>  7 HlyE_IgA        7     1 0.684   9.62 0.602 0.0000407   1.06
#>  8 HlyE_IgA        8     1 0.894  42.9  0.717 0.0000443   1.06
#>  9 HlyE_IgA        9     1 1.35    8.42 0.713 0.0000592   1.04
#> 10 HlyE_IgA       10     1 1.54  113.   0.415 0.00000526  1.04
#> # ℹ 390 more rows
```
