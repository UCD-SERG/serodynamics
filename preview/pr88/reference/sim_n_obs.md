# Simulate number of longitudinal observations

Simulate number of longitudinal observations

## Usage

``` r
sim_n_obs(dist_n_obs, n)
```

## Arguments

- dist_n_obs:

  distribution of number of longitudinal observations

- n:

  number of participants to simulate

## Value

an [integer](https://rdrr.io/r/base/integer.html)
[vector](https://rdrr.io/r/base/vector.html)

## Examples

``` r
 dist_n_obs = tibble::tibble(n_obs = 1:5, prob = 1/5)
 dist_n_obs |> sim_n_obs(n = 10)
#>  [1] 1 5 4 3 2 2 2 2 3 2
```
