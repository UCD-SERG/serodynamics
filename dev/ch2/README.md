# `dev/ch2` — Chapter 2 simulation study

Author: Kwan Ho Lee

Simulation-based validation of the correlated two-biomarker (IgG-IgA) extension
of the within-host antibody kinetics model, plus its application to the Shigella
SOSAR cohort.

**This directory is not part of the R package.** It is excluded from the build
via `.Rbuildignore` and from linting via `.lintr.R`, and it depends on Stan
(`cmdstanr`), which `serodynamics` does not.

---

## Where to start

| If you want to know | Read |
|---|---|
| what the model is | `model_ch2.stan` |
| how the correlation is injected into a simulation | `make_corr_curve_params.R` in the package `R/` (branch `sim-noise`) |
| where the simulation truth comes from | `rebuild_ch2_truth_targets.R` -- the header records the source fit, the number of draws, and its max R-hat |
| exactly what was run, with which settings | the `.tsv` manifests below -- one line per fitted cell |
| how a run is launched | `run_jobs.sh` |

---

## The model

Chapter 1 fits each antigen isotype with its own 5x5 covariance of subject-level
curve parameters. Chapter 2 adds a cross-biomarker block so a subject's IgG and
IgA parameters may covary. The block is diagonal -- one correlation per curve
parameter -- and the joint covariance is built as

```
L = [[L_G,  0    ],       B = diag(c) inv(L_G)'
     [B,    L_A|G]]       L_A|G = chol(Sigma_A - B B')
```

so the cross block is exactly `diag(c)`, both within-biomarker blocks are
unchanged, and `c = 0` recovers Chapter 1 exactly.

---

## Pipeline

```
rebuild_ch2_truth_targets.R   fit to real data -> mu, Sigma, prec_logy
        |
make_corr_curve_params()      joint draws with a known cross-correlation
        |
sim_case_data(noise_sd = ...) visit schedule + curve + log-scale measurement error
        |
run_mod_stan_ch2()            fit model_ch2.stan (estimate_c = 0 or 1)
        |
ch2_metrics.R                 bias, MSE, posterior variance, coverage
```

---

## Files, by role

### Model and core functions

| file | purpose |
|---|---|
| `model_ch2.stan` | Stan model: two-phase kinetics with a diagonal cross-biomarker block |
| `stan_ch2_functions.R` | `prep_ch2_standata()`, `run_mod_stan_ch2()` |
| `ch2_sim_functions.R` | `scenario_truth()`, `sim_ch2_clustered()`, `recovery_metrics()` |

### Setting up the simulation truth

| file | purpose |
|---|---|
| `rebuild_ch2_truth_targets.R` | regenerates `ch2_truth_targets.rds` from recorded values. The header carries the provenance, so the file itself is not committed |
| `extract_fit_ch2_targets.R` | derives those values from a saved fit |
| `ch2_fit_to_curve_params.R` | fit -> `curve_params`, for simulating from a fitted population |

### Running cells

| file | purpose |
|---|---|
| `ch2_run_one.R` | **current.** One simulation cell: one sample size, one seed, one arm |
| `ch2_run_shigella.R` | **current.** Fits the model to the real Shigella cohort |
| `ch2_sim_one.R` | *superseded by `ch2_run_one.R`.* Kept because earlier results were produced with it |

### Launchers

`run_jobs.sh` is the general one and the only one needed for new work. The other
two predate it and are kept so that earlier runs can be reproduced exactly.

| file | purpose |
|---|---|
| `run_jobs.sh` | **current.** Concurrent runner driven by a manifest; keeps a fixed number of cells alive and queues the rest |
| `run_probe.sh` | short runs used to choose a sampler setting that converges |
| `run_production.sh` | the first multi-seed recovery run |

### Manifests -- the record of what was actually run

Each line is one fitted cell: a name, a script, and every setting passed to it.
These are the reason a claim like "eight seeds were rerun at `adapt_delta =
0.999`" can be checked rather than taken on trust.

| file | what it ran |
|---|---|
| `jobs_rerun.tsv` | the eight cells that missed R-hat < 1.1, rerun at `adapt_delta = 0.999`, `max_treedepth = 13`, warmup 9000 |
| `jobs_shigella_v2.tsv` | **current.** Shigella: `c1_free` (16 chains, narrow init) and `shig_c0` (`estimate_c = 0`, the Chapter 1 arm needed for a LOO comparison) |
| `jobs_tail.tsv` | tests whether decay-shape is weakly identified because of the model or because of the follow-up schedule |
| `jobs_shigella.tsv` | *superseded by `jobs_shigella_v2.tsv`* |

### Analysis

| file | purpose |
|---|---|
| `ch2_metrics.R` | **current.** Pools converged seeds into bias, MSE, posterior variance and coverage, and writes the coverage figure. Takes one or more directories, so archived and new results can be combined |
| `ch2_recovery_metrics.R` | *superseded by `ch2_metrics.R`.* Kept for the earlier study |

### Input preparation

| file | purpose |
|---|---|
| `make_ch2_shigella_input.R` | carves one antigen's IgG/IgA pair out of the SOSAR cohort |
| `harness_dryrun.R` | runs the package-side files with stubbed dependencies, so plumbing errors surface without Stan |

---

## Running it

```bash
PKG_DIR=/path/to/serodynamics JOBS=jobs_rerun.tsv CORES_PER_JOB=8 \
  nohup ./run_jobs.sh > jobs.out 2>&1 &
```

Every cell writes `res_<TAG>.rds` independently and copies its CmdStan CSVs into
`csv_<TAG>/`, so a crash in one cell leaves the others untouched and a completed
fit survives a post-processing error.

```bash
Rscript ch2_metrics.R trial4 .      # combine archived and current results
```

---

## Applying the model to Shigella

The cross-biomarker correlation is a within-person quantity, so both isotypes
have to come from the same subject set. Chapter 1 fitted each antigen-isotype
independently and could pick a different subset for each, which is not available
here. `make_ch2_shigella_input.R` therefore takes an explicit subset:

| subset | subjects | when to use |
|---|---|---|
| `overall` | 48 | ipaB, a virulence protein conserved across serotypes |
| `flexneri` | 25 | Sf2a, pooling Sf2a- and Sf3a-infected subjects (cross-reactivity) |
| `serotype` | 5-17 | the other O-antigens; too few subjects to identify a 10-dimensional covariance |

`prep_ch2_standata()` filters on `isos`, whose default is the typhoid antigen
names, so the Shigella isotype labels have to be supplied or relabelled. The
runner matches isotype suffixes rather than position -- a positional map
silently swaps IgG and IgA, since the sorted labels put IgA first while the
defaults put IgG first.

---

## Things worth knowing before reading the diagnostics

* Measurement error enters on the **log** scale, matching `model.jags` L54 and
  `model_ch2.stan` L110. Simulating without it drives `prec_logy` towards the
  boundary and degrades the sampler geometry.
* The latent dimension is `nsubj x 10` (plus the non-centred `z`), so the
  posterior grows linearly in the number of simulated subjects. This, not
  `max_treedepth`, is what limits the feasible sample size.
* `cross_corr[3]` (time-to-peak) sits closest to the boundary and is the last to
  converge; `cross_corr[5]` (decay shape) converges easily but its interval spans
  zero. The two failures are at opposite ends and need different responses.
* The log-spaced schedule takes the first `n_obs` points of a fixed grid, so
  `n_obs` sets the observation **window**, not just its density. Under the
  default uniform draw the median subject stops at day 30 of a 400-day grid.
  `MIN_N_OBS` in `ch2_run_one.R` controls this.

## Requirements

`cmdstanr` and a working CmdStan install, plus `serodynamics` loaded via
`devtools::load_all()`. Set `PKG_DIR` to the package root before running the
shell scripts.
