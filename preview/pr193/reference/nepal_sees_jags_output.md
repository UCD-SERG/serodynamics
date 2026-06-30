# SEES Typhoid run_serodynamics jags output

A
[`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/run_serodynamics.md)
output using the
[nepal_sees](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/nepal_sees.md)
example data set as input and stratifying by column `"bldculres"`, which
is the diagnosis type (typhoid or paratyphoid). Keeping only IDs
`"newperson"`, `"sees_npl_1"`, `"sees_npl_2"`.

## Usage

``` r
nepal_sees_jags_output
```

## Format

An S3 object of class `sr_model`: A
[tibble::tbl_df](https://tibble.tidyverse.org/reference/tbl_df-class.html)
that contains the posterior predictive distribution of the
person-specific parameters for a "new person" with no observed data
(`Subject = "newperson"`) and posterior distributions of the
person-specific parameters for two arbitrarily-chosen subjects
(`"sees_npl_1"` and `"sees_npl_2"`). Contains 40,000 `rows`, 7
`columns`, and model `attributes`.

- Iteration:

  Number of sampling iterations: 500 iterations

- Chain:

  Number of MCMC chains run: 2 chains run

- Parameter:

  Parameter being estimated

- Iso_type:

  Antibody/antigen type combination being evaluated: `HlyE_IgA` and
  `HlyE_IgG`

- Stratification:

  The variable used to stratify jags model: `typhi` and `paratyphi`

- Subject:

  ID of subject being evaluated: `newperson`, `sees_npl_1`, `sees_npl_2`

- value:

  Estimated value of the parameter

- attributes:

  A [list](https://rdrr.io/r/base/list.html) of `attributes` that
  summarize the jags inputs, priors, optional jags_post mcmc object, and
  population-level parameters. Includes a `population_params` attribute
  with posterior samples of the population-level parameters (`mu.par`,
  `prec.par`, `prec.logy`), indexed by `Iteration`, `Chain`,
  `Parameter`, `Iso_type`, `Stratification`, and `Population_Parameter`.

## Source

reference study:
[doi:10.1016/S2666-5247(22)00114-8](https://doi.org/10.1016/S2666-5247%2822%2900114-8)
