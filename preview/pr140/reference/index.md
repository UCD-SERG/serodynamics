# Package index

## Simulate case data

- [`sim_case_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/sim_case_data.md)
  : Simulate longitudinal case follow-up data from a homogeneous
  population

## Prepare data for analysis

- [`serodynamics_example()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/serodynamics_example.md)
  : Get path to an example file

- [`load_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/load_data.md)
  : load and format data

- [`as_case_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/as_case_data.md)
  :

  Convert data into `case_data`

- [`prep_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/prep_data.md)
  : prepare data for JAGs

## Visualize data

- [`autoplot(`*`<case_data>`*`)`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/autoplot.case_data.md)
  : Plot case data

## Prepare auxiliary JAGS inputs

- [`prep_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/prep_priors.md)
  : Prepare priors
- [`initsfunction()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/initsfunction.md)
  : JAGS chain initialization function

## Model seroreponse

- [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/run_mod.md)
  : Run Jags Model

## Model diagnostics

- [`plot_jags_dens()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/plot_jags_dens.md)
  : Density Plot Diagnostics
- [`plot_jags_Rhat()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/plot_jags_Rhat.md)
  : Rhat Plot Diagnostics
- [`plot_jags_trace()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/plot_jags_trace.md)
  : Trace Plot Diagnostics
- [`plot_jags_effect()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/plot_jags_effect.md)
  : Plot Effective Sample Size Diagnostics
- [`plot_predicted_curve()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/plot_predicted_curve.md)
  : Generate Predicted Antibody Response Curves (Median + 95% CI)

## Postprocess JAGS output

- [`postprocess_jags_output()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/postprocess_jags_output.md)
  : Postprocess JAGS output

## Summarize seroresponse model estimates

- [`post_summ()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/post_summ.md)
  : Summary Table of Jags Posterior Estimates

## Example data sets

- [`serodynamics_example()`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/serodynamics_example.md)
  : Get path to an example file
- [`nepal_sees`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/nepal_sees.md)
  : SEES Typhoid data
- [`nepal_sees_jags_output`](https:/ucd-serg.github.io/serodynamics/preview/pr140/reference/nepal_sees_jags_output.md)
  : SEES Typhoid run_mod jags output
