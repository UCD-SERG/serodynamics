# dobson

``` r
library(serodynamics)
#> Registered S3 method overwritten by 'GGally':
#>   method from   
#>   +.gg   ggplot2
library(rjags)
#> Loading required package: coda
#> Linked to JAGS 4.3.2
#> Loaded modules: basemod,bugs
library(runjags)
runjags::findJAGS()
#> [1] "/usr/bin/jags"
```

``` r

data1 <- rbinom(n = 91, size = 1, prob = .6)
jags_post0 <- run.jags(
  model = fs::path_package("serodynamics", "extdata/model.dobson.jags"),
  data = list(r = data1, N = length(data1)),
  monitor = "p"
)
#> Warning: No initial value blocks found and n.chains not specified: 2 chains
#> were used
#> Warning: No initial values were provided - JAGS will use the same initial
#> values for all chains
#> Compiling rjags model...
#> Calling the simulation using the rjags method...
#> Note: the model did not require adaptation
#> Burning in the model for 4000 iterations...
#> Running the model for 10000 iterations...
#> Simulation complete
#> Calculating summary statistics...
#> Calculating the Gelman-Rubin statistic for 1 variables....
#> Finished running the simulation

jags_post0$mcmc |> as.array() |> head()
#>       chain
#> iter        [,1]      [,2]
#>   5001 0.7218262 0.6509717
#>   5002 0.6450394 0.6476425
#>   5003 0.6287756 0.6479770
#>   5004 0.7023559 0.5929750
#>   5005 0.6474343 0.5814139
#>   5006 0.6540227 0.6643686
```
