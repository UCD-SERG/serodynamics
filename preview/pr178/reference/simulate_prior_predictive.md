# Simulate antibody trajectories from priors only

Performs a prior predictive check by simulating antibody trajectories
and measurements using only the prior distributions, before fitting the
model to data. This is useful for assessing whether priors generate
realistic antibody values for a given pathogen and assay.

## Usage

``` r
simulate_prior_predictive(
  prepped_data,
  prepped_priors,
  n_sims = 1,
  seed = NULL
)
```

## Arguments

- prepped_data:

  A `prepped_jags_data` object from
  [`prep_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr178/reference/prep_data.md)

- prepped_priors:

  A `curve_params_priors` object from
  [`prep_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr178/reference/prep_priors.md)

- n_sims:

  [integer](https://rdrr.io/r/base/integer.html) Number of prior
  predictive simulations to generate (default = 1). If \> 1, returns a
  list of simulated datasets.

- seed:

  [integer](https://rdrr.io/r/base/integer.html) Optional random seed
  for reproducibility

## Value

If `n_sims = 1`, a `prepped_jags_data` object with simulated antibody
values replacing the observed values. If `n_sims > 1`, a
[list](https://rdrr.io/r/base/list.html) of such objects.

## Details

This function:

1.  Draws kinetic parameters from the prior distributions specified by
    [`prep_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr178/reference/prep_priors.md)

2.  Generates latent antibody trajectories using the same within-host
    antibody model used in the JAGS model

3.  Applies measurement noise to simulate observed antibody values

4.  Preserves the original dataset structure (IDs, biomarkers,
    timepoints)

The simulation follows the hierarchical model structure:

- Population-level parameters are drawn from hyperpriors

- Individual-level parameters are drawn from population distributions

- Observations are generated with log-normal measurement error

## Examples

``` r
# Prepare data and priors
set.seed(1)
raw_data <- serocalculator::typhoid_curves_nostrat_100 |>
  sim_case_data(n = 5)
prepped_data <- prep_data(raw_data)
prepped_priors <- prep_priors(max_antigens = prepped_data$n_antigen_isos)

# Simulate from priors
sim_data <- simulate_prior_predictive(prepped_data, prepped_priors)

# Generate multiple simulations
sim_list <- simulate_prior_predictive(
  prepped_data, prepped_priors, n_sims = 10
)
```
