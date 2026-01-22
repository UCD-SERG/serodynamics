# Summarize prior predictive simulations

Provides diagnostic summaries of prior predictive simulations to
identify potential issues with prior specifications before fitting the
model.

## Usage

``` r
summarize_prior_predictive(sim_data, original_data = NULL)
```

## Arguments

- sim_data:

  A simulated `prepped_jags_data` object from
  [`simulate_prior_predictive()`](https:/ucd-serg.github.io/serodynamics/preview/pr178/reference/simulate_prior_predictive.md),
  or a [list](https://rdrr.io/r/base/list.html) of such objects

- original_data:

  Optional original `prepped_jags_data` object from
  [`prep_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr178/reference/prep_data.md)
  to compare simulated vs observed ranges

## Value

A [list](https://rdrr.io/r/base/list.html) containing:

- `n_sims`: Number of simulations summarized

- `validity_check`: [data.frame](https://rdrr.io/r/base/data.frame.html)
  with counts of finite, non-finite, and negative values by biomarker

- `range_summary`: [data.frame](https://rdrr.io/r/base/data.frame.html)
  with min, max, median, and IQR of simulated values by biomarker

- `observed_range`: (if `original_data` provided)
  [data.frame](https://rdrr.io/r/base/data.frame.html) with observed
  data ranges for comparison

- `issues`: [character](https://rdrr.io/r/base/character.html)
  [vector](https://rdrr.io/r/base/vector.html) describing any detected
  problems

## Details

This function checks for:

- Non-finite values (NaN, Inf, -Inf)

- Negative antibody values (which would be invalid on natural scale)

- Summary statistics by biomarker (min, max, median, IQR)

- Optional comparison to observed data ranges

## Examples

``` r
# Prepare data and priors
set.seed(1)
raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
  sim_case_data(n = 5)
prepped_data <- prep_data(raw_data)
prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

# Simulate and summarize
sim_data <- simulate_prior_predictive(
  prepped_data, prepped_priors, n_sims = 10
)
summary <- summarize_prior_predictive(
  sim_data, original_data = prepped_data
)
print(summary)
#> 
#> ── Prior Predictive Check Summary ──────────────────────────────────────────────
#> Based on 10 simulations
#> 
#> 
#> ── Validity Check ──
#> 
#>   biomarker n_finite n_nonfinite n_negative
#> 1  HlyE_IgA      240           0         86
#> 2  HlyE_IgG      240           0         62
#> 3   LPS_IgA      228           0         88
#> 4   LPS_IgG      240           0         38
#> 5    Vi_IgG      240           0        108
#> 
#> 
#> ── Simulated Range Summary (log scale) ──
#> 
#>   biomarker        min         q25      median       q75      max
#> 1  HlyE_IgA -132.94047 -24.1104472  0.06340139  1.214377 389.8255
#> 2  HlyE_IgG -183.14391  -4.7592531 -0.24743225  1.573577 283.0524
#> 3   LPS_IgA -220.76280 -22.0845294 -0.60462287  1.074853 268.9564
#> 4   LPS_IgG  -96.27452  -0.5066702  2.75640580 34.933135 160.1784
#> 5    Vi_IgG  -77.86039 -21.7555093 -0.68681588 20.334114 537.7100
#> 
#> 
#> ── Observed Data Range (log scale) ──
#> 
#>   biomarker    obs_min obs_median  obs_max
#> 1  HlyE_IgA -0.3515210   3.044714 6.092787
#> 2  HlyE_IgG  0.6198680   4.080171 6.944626
#> 3   LPS_IgA -0.0489027   3.144906 5.776118
#> 4   LPS_IgG -0.1743850   2.721963 6.726204
#> 5    Vi_IgG  0.4358270   5.499178 6.980447
#> 
#> 
#> ── Issues Detected ──
#> 
#> ! Very low/negative log-scale values detected for biomarker(s): HlyE_IgA,
#>   HlyE_IgG, LPS_IgA, LPS_IgG, Vi_IgG (may indicate prior-data scale mismatch)
#> ! Simulated range for HlyE_IgA is much wider than observed data (may indicate
#>   over-dispersed priors)
#> ! Simulated range for HlyE_IgG is much wider than observed data (may indicate
#>   over-dispersed priors)
#> ! Simulated range for LPS_IgA is much wider than observed data (may indicate
#>   over-dispersed priors)
#> ! Simulated range for LPS_IgG is much wider than observed data (may indicate
#>   over-dispersed priors)
#> ! Simulated range for Vi_IgG is much wider than observed data (may indicate
#>   over-dispersed priors)
```
