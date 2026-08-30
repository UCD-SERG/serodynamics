# Simulate longitudinal data (serodynamics trajectory)

`simulate_multi_b_long()` simulates subject-level latent parameters with
a Kronecker covariance \\\Sigma_B \otimes \Sigma_P\\ (5 parameters per
biomarker), then generates noisy observations on a time grid. The
expected trajectory is computed directly using `serodynamics::ab()`.

## Usage

``` r
simulate_multi_b_long(
  n_id,
  n_blocks,
  time_grid,
  sigma_p,
  sigma_b,
  mu_latent_base = c(log(1), log(5), log(30), log(0.02), log(1.5)),
  meas_sd = rep(0.22, n_blocks)
)
```

## Arguments

- n_id:

  Integer. Number of individuals to simulate.

- n_blocks:

  Integer. Number of biomarkers (blocks).

- time_grid:

  Numeric vector of observation times (days).

- sigma_p:

  5×5 covariance matrix for within-biomarker parameters.

- sigma_b:

  `n_blocks`×`n_blocks` covariance across biomarkers.

- mu_latent_base:

  Numeric length-5 vector of means for the latent parameters (on log
  scale) per biomarker, in the order
  `(log y0, log(y1 - y0), log t1, log alpha, log(shape-1))`.

- meas_sd:

  Numeric. Measurement error SD(s) on the log scale; either a single
  value recycled to all biomarkers or a length-`n_blocks` vector.

## Value

A list with:

- `data`: tibble with columns `Subject`, `visit_num`, `antigen_iso`,
  `time_days`, `value`.

- `truth`: list with `m_true`, `sigma_p`, `sigma_b`, `sigma_total`,
  `meas_sd`, and `theta_latent`.

## Author

Kwan Ho Lee

## Examples

``` r
set.seed(925)

# Define dimensions and covariances
n_blocks  <- 2
time_grid <- c(0, 7, 14, 30)

sd_p <- c(0.35, 0.45, 0.25, 0.30, 0.25)
R_p  <- matrix(0.25, 5, 5)
diag(R_p) <- 1
sigma_p <- diag(sd_p) %*% R_p %*% diag(sd_p)

R_b <- matrix(c(1, 0.5,
                0.5, 1), n_blocks, n_blocks, byrow = TRUE)
sd_b   <- rep(0.6, n_blocks)
sigma_b <- diag(sd_b) %*% R_b %*% diag(sd_b)

# Use default serodynamics trajectory 
sim <- simulate_multi_b_long(
  n_id      = 5,
  n_blocks  = n_blocks,
  time_grid = time_grid,
  sigma_p   = sigma_p,
  sigma_b   = sigma_b
)

head(sim$data)
#> # A tibble: 6 × 5
#>   Subject visit_num antigen_iso time_days value
#>   <chr>       <int> <chr>           <dbl> <dbl>
#> 1 1               1 bm1                 0 0.850
#> 2 1               2 bm1                 7 1.37 
#> 3 1               3 bm1                14 1.50 
#> 4 1               4 bm1                30 3.10 
#> 5 1               1 bm2                 0 0.692
#> 6 1               2 bm2                 7 1.36 
```
