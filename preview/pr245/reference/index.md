# Package index

## Simulate case data

- [`sim_case_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/sim_case_data.md)
  : Simulate longitudinal case follow-up data from a homogeneous
  population

## Prepare data for analysis

- [`serodynamics_example()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/serodynamics_example.md)
  : Get path to an example file

- [`load_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/load_data.md)
  : load and format data

- [`as_case_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/as_case_data.md)
  :

  Convert data into `case_data`

- [`prep_data()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_data.md)
  : prepare data for JAGs

## Visualize data

- [`autoplot(`*`<case_data>`*`)`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/autoplot.case_data.md)
  : Plot case data

## Prepare auxiliary JAGS inputs

- [`prep_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors.md)
  : Prepare priors
- [`initsfunction()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/initsfunction.md)
  : JAGS chain initialization function

## Model seroreponse

- [`run_mod()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod.md)
  : Run Jags Model

## Model diagnostics

- [`plot_jags_dens()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/plot_jags_dens.md)
  : Density Plot Diagnostics
- [`plot_jags_Rhat()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/plot_jags_Rhat.md)
  : Rhat Plot Diagnostics
- [`plot_jags_trace()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/plot_jags_trace.md)
  : Trace Plot Diagnostics
- [`plot_jags_effect()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/plot_jags_effect.md)
  : Plot Effective Sample Size Diagnostics
- [`plot_predicted_curve()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/plot_predicted_curve.md)
  : Generate Predicted Antibody Response Curves (Median + 95% CI)

## Postprocess JAGS output

- [`postprocess_jags_output()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/postprocess_jags_output.md)
  : Postprocess JAGS output

## Summarize seroresponse model estimates

- [`post_summ()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/post_summ.md)
  : Summary Table of Jags Posterior Estimates

## Model 2a: cross-biomarker extension (Chapter 2)

Chapter 2 extension that adds a same-parameter cross-biomarker
covariance to the Chapter 1 model via a shared latent factor (strictly
nests Chapter 1).

- [`run_mod_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/run_mod_2a.md)
  : Fit Model 2a (Chapter 1 + alpha) with JAGS
- [`compare_mod_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/compare_mod_2a.md)
  : Compare Chapter 1 and Model 2a on the same data
- [`fit_chapter1_lean()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/fit_chapter1_lean.md)
  : Lean Chapter 1 fit (for comparison with Model 2a)
- [`summarize_cross_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/summarize_cross_2a.md)
  : Summarize cross-biomarker covariance from a Model 2a fit
- [`summarize_curve_params_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/summarize_curve_params_2a.md)
  : Summarize shared curve-parameter posteriors
- [`validate_recovery_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/validate_recovery_2a.md)
  : Validate Model 2a parameter recovery
- [`validate_nesting_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/validate_nesting_2a.md)
  : Validate the Chapter 1 nesting / no-false-positive behaviour
- [`sim_case_data_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/sim_case_data_2a.md)
  : Simulate longitudinal case data with known cross-biomarker
  covariance
- [`sim_params_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/sim_params_2a.md)
  : Simulate subject-level parameters with a known Model 2a covariance
- [`prep_priors_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/prep_priors_2a.md)
  : Prepare priors for Model 2a
- [`add_factor_priors()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/add_factor_priors.md)
  : Append Model 2a factor priors to a Chapter 1 prior list
- [`jags_data_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/jags_data_2a.md)
  : Build the combined JAGS input list for Model 2a
- [`make_inits_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/make_inits_2a.md)
  : Initial-value factory for Model 2a chains
- [`build_sigma_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/build_sigma_2a.md)
  : Assemble a Model 2a covariance matrix
- [`cross_cov_from_loadings()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/cross_cov_from_loadings.md)
  : Convert factor loadings to cross-biomarker covariance
- [`cross_cor_from_draw_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/cross_cor_from_draw_2a.md)
  : Convert loadings + precisions to cross-biomarker correlation
- [`marginal_var_2a()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/marginal_var_2a.md)
  : Marginal within-biomarker variance under the factor model

## Example data sets

- [`serodynamics_example()`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/serodynamics_example.md)
  : Get path to an example file
- [`nepal_sees`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/nepal_sees.md)
  : SEES Typhoid data
- [`nepal_sees_jags_output`](https:/ucd-serg.github.io/serodynamics/preview/pr245/reference/nepal_sees_jags_output.md)
  : SEES Typhoid run_mod jags output
