# Package index

## Simulate case data

- [`sim_case_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/sim_case_data.md)
  : Simulate longitudinal case follow-up data from a homogeneous
  population

## Prepare data for analysis

- [`serodynamics_example()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/serodynamics_example.md)
  : Get path to an example file

- [`load_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/load_data.md)
  : load and format data

- [`as_case_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/as_case_data.md)
  :

  Convert data into `case_data`

- [`prep_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/prep_data.md)
  : prepare data for JAGs

## Visualize data

- [`autoplot(`*`<case_data>`*`)`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/autoplot.case_data.md)
  : Plot case data

## Prepare auxiliary JAGS inputs

- [`prep_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/prep_priors.md)
  : Prepare priors
- [`initsfunction()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/initsfunction.md)
  : JAGS chain initialization function

## Model seroreponse

- [`run_serodynamics()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/run_serodynamics.md)
  : Run Jags Model

## Model diagnostics

- [`plot_density()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/plot_density.md)
  : Density Plot Diagnostics
- [`plot_rhat()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/plot_rhat.md)
  : Rhat Plot Diagnostics
- [`plot_trace()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/plot_trace.md)
  : Trace Plot Diagnostics
- [`plot_ess()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/plot_ess.md)
  : Plot Effective Sample Size Diagnostics

## Postprocess JAGS output

- [`postprocess_jags_output()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/postprocess_jags_output.md)
  : Postprocess JAGS output

## Summarize seroresponse model estimates

- [`summarize_posterior()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/summarize_posterior.md)
  : Summary Table of Jags Posterior Estimates

## Visualize model results

- [`plot_predicted_curve()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/plot_predicted_curve.md)
  : Generate Predicted Antibody Response Curves (Median + 95% CI)
- [`plot_serocurve()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/plot_serocurve.md)
  : Plot Estimated Serodynamic Curves at the Population Level

## Example data sets

- [`serodynamics_example()`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/serodynamics_example.md)
  : Get path to an example file
- [`nepal_sees`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/nepal_sees.md)
  : SEES Typhoid data
- [`nepal_sees_jags_output`](https:/ucd-serg.github.io/serodynamics/preview/pr193/reference/nepal_sees_jags_output.md)
  : SEES Typhoid run_serodynamics jags output
