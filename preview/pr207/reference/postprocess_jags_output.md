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
#> Welcome to JAGS 4.3.2 on Wed Jun 17 21:11:17 2026
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
#> . Adapting 100
#> -------------------------------------------------| 100
#> ++++++++++++++++++++++++++++++++++++++++++++++++++ 100%
#> Adaptation incomplete.
#> . Updating 100
#> -------------------------------------------------| 100
#> ************************************************** 100%
#> . . . . . . Updating 100
#> -------------------------------------------------| 100
#> ************************************************** 100%
#> . . . . Updating 0
#> . Deleting model
#> . 
#> All chains have finished
#> Warning: The adaptation phase of one or more models was not completed in 100 iterations, so the current samples may not be optimal - try increasing the number of iterations to the "adapt" argument
#> Simulation complete.  Reading coda files...
#> Coda files loaded successfully
#> Finished running the simulation

curve_params <- jags_post |> postprocess_jags_output(
  ids = attr(prepped_data, "ids"),
  antigen_isos = attr(prepped_data, "antigens")
)

print(curve_params)
#> # A tibble: 400 × 8
#>    antigen_iso  iter chain    y0       y1    t1    alpha     r
#>    <fct>       <int> <int> <dbl>    <dbl> <dbl>    <dbl> <dbl>
#>  1 HlyE_IgA        1     1 2.72      9.61  3.28 0.00160   2.47
#>  2 HlyE_IgA        2     1 0.881 19020.    3.91 0.00272   1.44
#>  3 HlyE_IgA        3     1 1.38    805.    2.54 0.00225   2.18
#>  4 HlyE_IgA        4     1 0.821    38.4   2.41 0.00321   1.94
#>  5 HlyE_IgA        5     1 1.29     43.7   2.51 0.00431   2.15
#>  6 HlyE_IgA        6     1 1.28   2881.    1.81 0.00184   2.33
#>  7 HlyE_IgA        7     1 1.84    391.    2.52 0.00221   1.95
#>  8 HlyE_IgA        8     1 2.49    713.    2.51 0.00121   2.15
#>  9 HlyE_IgA        9     1 1.29     45.1   4.00 0.00709   1.90
#> 10 HlyE_IgA       10     1 1.80      3.17  1.91 0.000896  1.83
#> # ℹ 390 more rows
```
