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
#> Welcome to JAGS 4.3.2 on Fri Jan  9 10:01:37 2026
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
#>  1 HlyE_IgA        1     1 1.14   67.1   7.24 0.000538  1.40
#>  2 HlyE_IgA        2     1 0.841  17.5   6.86 0.00109   1.20
#>  3 HlyE_IgA        3     1 1.15   17.1   3.54 0.000182  1.38
#>  4 HlyE_IgA        4     1 1.04    2.18  7.87 0.000335  1.32
#>  5 HlyE_IgA        5     1 1.43   69.5   5.51 0.000804  1.32
#>  6 HlyE_IgA        6     1 1.05  368.    7.51 0.00713   1.21
#>  7 HlyE_IgA        7     1 0.791   6.90  6.60 0.000543  1.27
#>  8 HlyE_IgA        8     1 1.03    1.62  8.93 0.00161   1.50
#>  9 HlyE_IgA        9     1 0.720  16.4   7.66 0.00102   1.27
#> 10 HlyE_IgA       10     1 1.02    3.20  5.57 0.00173   1.31
#> # ℹ 390 more rows
```
