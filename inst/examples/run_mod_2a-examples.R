# Model 2a (Chapter 1 + alpha) -- example usage.
# Mirrors run_mod-examples.R: one representative fit when JAGS is available.
# Heavier validation / comparison calls are shown commented out (run locally).
if (!is.element(runjags::findjags(), c("", NULL))) {
  library(serodynamics)

  # nepal_sees ships as `case_data` with exactly two biomarkers:
  # HlyE_IgG and HlyE_IgA. It is already in the right format -- pass it directly.
  data(nepal_sees)

  fit <- run_mod_2a(
    data = nepal_sees,
    file_mod = serodynamics_example("model_2a.jags"),
    nchain = 4, nadapt = 100, nburn = 100, nmc = 1000, niter = 2000
  )

  # cross-biomarker (IgG ~ IgA) covariance & correlation, per kinetic parameter
  print(fit$cross)

  # ---- run these locally (Mercury) at full length; omitted from routine check:
  # validate_recovery_2a()                  # recover a known correlation
  # validate_nesting_2a()                   # ~0 when there is none
  # cmp <- compare_mod_2a(nepal_sees)       # Chapter 1 vs Model 2a
  # print(cmp$shared); print(cmp$added)     # shared params + the addition
}
