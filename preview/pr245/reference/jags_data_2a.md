# Build the combined JAGS input list for Model 2a

Assembles the single named list that `model_2a.jags` consumes, by
combining the prepared longitudinal data
([`prep_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_data.md),
reused unchanged from Chapter 1) with the Model 2a priors
([`prep_priors_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors_2a.md)).
The biomarker labels from
[`prep_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_data.md)
are carried along as an attribute so downstream summaries can label the
two biomarkers.

## Usage

``` r
jags_data_2a(data, prec_lambda = 0.25, add_newperson = TRUE, ...)
```

## Arguments

- data:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) in
  `serocalculator` case-data format (columns `antigen_iso`, `visit_num`,
  a value column, and a time column).

- prec_lambda:

  Prior precision of the factor loadings, forwarded to
  [`prep_priors_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors_2a.md).
  Default `0.25`.

- add_newperson:

  [logical](https://rdrr.io/r/base/logical.html); forwarded to
  [`prep_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_data.md).
  Default `TRUE` to match Chapter 1 (adds a dummy subject for posterior
  prediction).

- ...:

  Additional Chapter 1 prior arguments forwarded to
  [`prep_priors_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors_2a.md).

## Value

A named [list](https://rdrr.io/r/base/list.html) of JAGS inputs, with
attribute `"antigens"` (the biomarker labels) and `"ids"` (subject ids).
