# Prepare data for Stan

Prepare data for Stan

## Usage

``` r
prep_data_stan(
  dataframe,
  biomarker_column = get_biomarker_names_var(dataframe),
  verbose = FALSE
)
```

## Arguments

- dataframe:

  a [data.frame](https://rdrr.io/r/base/data.frame.html) containing case
  data

- biomarker_column:

  [character](https://rdrr.io/r/base/character.html) string indicating
  which column contains antigen-isotype names

- verbose:

  whether to produce verbose messaging

## Value

a `prepped_stan_data` object (a named
[list](https://rdrr.io/r/base/list.html)) with the following elements
ready for passing to CmdStanR:

- `nsubj`: integer, number of subjects

- `n_antigen_isos`: integer, number of antigen-isotype combinations

- `n_params`: integer, number of curve parameters (always 5: y0, y1, t1,
  alpha, shape)

- `nsmpl`: integer vector of length `nsubj`, number of observations per
  subject

- `max_nsmpl`: integer, maximum of `nsmpl` (determines array dimensions)

- `smpl_t`: numeric matrix `[nsubj, max_nsmpl]` of observation times.
  Positions beyond `nsmpl[subj]` are padded with **0** (not `NA`).

- `logy`: numeric array `[nsubj, max_nsmpl, n_antigen_isos]` of log
  antibody values. Positions beyond `nsmpl[subj]` are padded with **0**.
  Unlike the JAGS output from
  [`prep_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr175/reference/prep_data.md),
  which uses `NA` for padding, Stan requires numeric values; the model
  ignores padded entries by looping only up to `nsmpl[subj]`.

## See also

[`sample_predictive_stan()`](https:/ucd-serg.github.io/serodynamics/preview/pr175/reference/sample_predictive_stan.md)
for posterior predictive sampling with Stan models

## Examples

``` r
set.seed(1)
raw_data <-
  serocalculator::typhoid_curves_nostrat_100 |>
  sim_case_data(n = 5)
prepped_data <- prep_data_stan(raw_data)
```
