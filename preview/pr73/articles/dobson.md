# dobson

``` r
library(serodynamics)
library(rjags)
#> Loading required package: coda
#> Linked to JAGS 4.3.2
#> Loaded modules: basemod,bugs
library(runjags)
runjags::findJAGS()
#> [1] "/usr/bin/jags"
```

``` r

set.seed(1)
data1 <- rbinom(n = 91, size = 1, prob = .6)
jags_post0 <- run.jags(
  n.chains = 2,
  inits = initsfunction,
  model = serodynamics_example("model.dobson.jags"),
  data = list(r = data1, N = length(data1)),
  monitor = "p"
)
#> Compiling rjags model...
#> Calling the simulation using the rjags method...
#> Note: the model did not require adaptation
#> Burning in the model for 4000 iterations...
#> Running the model for 10000 iterations...
#> Simulation complete
#> Calculating summary statistics...
#> Calculating the Gelman-Rubin statistic for 1 variables....
#> Finished running the simulation
```

``` r
jags_post0$mcmc |> as.array() |> head()
#>       chain
#> iter        [,1]      [,2]
#>   5001 0.5846868 0.5503324
#>   5002 0.5766205 0.5624546
#>   5003 0.6519825 0.6281445
#>   5004 0.5982584 0.6042740
#>   5005 0.6118631 0.5834004
#>   5006 0.5656352 0.6063249
```
