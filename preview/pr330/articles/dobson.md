# dobson

``` r

library(serodynamics)
library(rjags)
#> Loading required package: coda
#> Linked to JAGS 5.0.2
#> Loaded modules: basemod,bugs,diag
library(runjags)
runjags::findJAGS()
#> [1] "/usr/local/bin/jags"
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
#>   5001 0.5505509 0.5529854
#>   5002 0.5967098 0.5899652
#>   5003 0.5382984 0.6684646
#>   5004 0.6431922 0.6102995
#>   5005 0.6395495 0.5982907
#>   5006 0.5603257 0.6231297
```
