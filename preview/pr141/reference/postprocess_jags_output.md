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
priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)
nchains <- 2
# nr of MC chains to run simultaneously
nadapt <- 1000
# nr of iterations for adaptation
nburnin <- 100
# nr of iterations to use for burn-in
nmc <- 100
# nr of samples in posterior chains
niter <- 200
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
#> Welcome to JAGS 4.3.2 on Tue Dec  9 19:37:59 2025
#> JAGS is free software and comes with ABSOLUTELY NO WARRANTY
#> Loading module: basemod: ok
#> Loading module: bugs: ok
#> . . Reading data file data.txt
#> . Compiling model graph
#>    Resolving undeclared variables
#>    Allocating nodes
#> Graph information:
#>    Observed stochastic nodes: 42
#>    Unobserved stochastic nodes: 24
#>    Total graph size: 930
#> . Reading parameter file inits1.txt
#> . Initializing model
#> . Adapting 1000
#> -------------------------------------------------| 1000
#> ++++++++++++++++++++++++++++++++++++++++++++++++++ 100%
#> Adaptation successful
#> . Updating 100
#> -------------------------------------------------| 100
#> ************************************************** 100%
#> . . . . . . Updating 200
#> -------------------------------------------------| 200
#> ************************************************** 100%
#> . . . . Updating 0
#> . Deleting model
#> . 
#> All chains have finished
#> Simulation complete.  Reading coda files...
#> Coda files loaded successfully
#> Finished running the simulation

curve_params <- jags_post |> postprocess_jags_output(
  ids = attr(prepped_data, "ids"),
  antigen_isos = attr(prepped_data, "antigens")
)

print(curve_params)
#> # A tibble: 400 × 8
#>    antigen_iso  iter chain    y0     y1    t1    alpha     r
#>    <fct>       <int> <int> <dbl>  <dbl> <dbl>    <dbl> <dbl>
#>  1 HlyE_IgA        1     1 1.39   77.1  10.7  0.00202   1.50
#>  2 HlyE_IgA        2     1 0.772  23.3  10.4  0.000669  1.38
#>  3 HlyE_IgA        3     1 1.01   19.2   3.23 0.000132  1.52
#>  4 HlyE_IgA        4     1 1.13    1.39  7.88 0.000579  1.49
#>  5 HlyE_IgA        5     1 1.54   83.6   6.11 0.000722  1.51
#>  6 HlyE_IgA        6     1 1.19  420.    8.36 0.00330   1.32
#>  7 HlyE_IgA        7     1 1.03    5.44  7.98 0.000382  1.41
#>  8 HlyE_IgA        8     1 1.40    3.24 11.0  0.00104   1.69
#>  9 HlyE_IgA        9     1 1.01   12.4   7.19 0.000357  1.54
#> 10 HlyE_IgA       10     1 1.12    2.18  6.46 0.000973  1.51
#> # ℹ 390 more rows
```
