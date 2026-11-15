# Package index

## Simulate case data

- [`sim_case_data()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/sim_case_data.md)
  : Simulate longitudinal case follow-up data from a homogeneous
  population

## Prepare data for analysis

- [`serodynamics_example()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/serodynamics_example.md)
  : Get path to an example file

&nbsp;

- [`load_data()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/load_data.md)
  : load and format data

&nbsp;

- [`as_case_data()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/as_case_data.md)
  :

  Convert data into `case_data`

&nbsp;

- [`prep_data()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/prep_data.md)
  : prepare data for JAGs

## Visualize data

- [`autoplot(`*`<case_data>`*`)`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/autoplot.case_data.md)
  : Plot case data

## Prepare auxiliary JAGS inputs

- [`prep_priors()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/prep_priors.md)
  : Prepare priors

&nbsp;

- [`initsfunction()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/initsfunction.md)
  : JAGS chain initialization function

## Model seroreponse

- [`run_mod()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/run_mod.md)
  : Run Jags Model

## Multivariate / Kronecker model (Chapter 2)

- [`clean_priors()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/clean_priors.md)
  : Drop legacy/unused prior fields

&nbsp;

- [`inits_kron()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/inits_kron.md)
  : Safe inits for the Kronecker model

&nbsp;

- [`prep_priors_multi_b()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/prep_priors_multi_b.md)
  : Priors for the Kronecker (multi-biomarker) model

&nbsp;

- [`simulate_multi_b_long()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/simulate_multi_b_long.md)
  : Simulate longitudinal data (serodynamics trajectory)

&nbsp;

- [`write_model_ch2_kron()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/write_model_ch2_kron.md)
  : Write the Chapter 2 Kronecker JAGS model

## Model diagnostics

- [`plot_jags_dens()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/plot_jags_dens.md)
  : Density Plot Diagnostics

&nbsp;

- [`plot_jags_Rhat()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/plot_jags_Rhat.md)
  : Rhat Plot Diagnostics

&nbsp;

- [`plot_jags_trace()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/plot_jags_trace.md)
  : Trace Plot Diagnostics

&nbsp;

- [`plot_jags_effect()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/plot_jags_effect.md)
  : Plot Effective Sample Size Diagnostics

&nbsp;

- [`plot_predicted_curve()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/plot_predicted_curve.md)
  : Generate Predicted Antibody Response Curves (Median + 95% CI)

## Postprocess JAGS output

- [`postprocess_jags_output()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/postprocess_jags_output.md)
  : Postprocess JAGS output

## Summarize seroresponse model estimates

- [`post_summ()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/post_summ.md)
  : Summary Table of Jags Posterior Estimates

## Example data sets

- [`serodynamics_example()`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/serodynamics_example.md)
  : Get path to an example file

&nbsp;

- [`nepal_sees`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/nepal_sees.md)
  : SEES Typhoid data

&nbsp;

- [`nepal_sees_jags_output`](https://ucd-serg.github.io/serodynamics/preview/pr133/reference/nepal_sees_jags_output.md)
  : SEES Typhoid run_mod jags output
