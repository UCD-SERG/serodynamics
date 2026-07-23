#!/usr/bin/env Rscript
# =====================================================================
# ch2_run_shigella.R -- fit the Chapter 2 correlated model to real Shigella data.
#
# Same durability design as ch2_run_one.R: the fit and its CSVs are written
# before any post-processing, and every post-processing block is wrapped, so a
# formatting error cannot cost hours of sampling.
#
# Unlike the simulation there is no known truth here, so the output is the
# posterior itself: the five cross-biomarker correlations, the two within-isotype
# covariances, and the measurement precision.
#
# Environment: DATA, TAG, NCHAIN, WARMUP, SAMP, ADAPT_DELTA, MAX_TD, SEED,
#              SAVE_FIT, PKG_DIR, CH2_DIR, MODEL_STAN
# =====================================================================
suppressPackageStartupMessages({ library(cmdstanr) })

DATA     <- Sys.getenv("DATA", "ch2_input_ipaB_overall.rds")
TAG      <- Sys.getenv("TAG", sub("\\.rds$", "", basename(DATA)))
PKG_DIR  <- Sys.getenv("PKG_DIR")
CH2_DIR  <- Sys.getenv("CH2_DIR", ".")
NCHAIN   <- as.integer(Sys.getenv("NCHAIN", "8"))
WARMUP   <- as.integer(Sys.getenv("WARMUP", "9000"))
SAMP     <- as.integer(Sys.getenv("SAMP", "4000"))
ADAPT    <- as.numeric(Sys.getenv("ADAPT_DELTA", "0.999"))
MAXTD    <- as.integer(Sys.getenv("MAX_TD", "13"))
SEED     <- as.integer(Sys.getenv("SEED", "1"))
SAVE_FIT <- as.integer(Sys.getenv("SAVE_FIT", "1"))
# cmdstanr's default init draws unconstrained parameters from [-2, 2]. This model
# has log_y1y0 near 11, so a default start can be far enough out that a chain
# never recovers: in the first run one chain of eight sat at lp = -240 against
# -60 for the rest, saturated treedepth on 99.3% of iterations, and dragged the
# whole job to 11.3 hours. A narrower init makes that much less likely.
INIT     <- Sys.getenv("INIT", "")
# FIX_C1=1 drops the baseline cross-covariance. The first run showed it is not
# identified in this design -- the estimated peak is at 1.5 days while every
# subject's first sample is at day 2, so the rise phase is unobserved and only
# the sign of that one correlation distinguishes the two posterior modes.
FIX_C1   <- as.integer(Sys.getenv("FIX_C1", "0"))
# ESTIMATE_C=0 fits the Chapter 1 model (all cross-covariances zero) on the same
# data. Running it alongside ESTIMATE_C=1 is what makes a LOO comparison
# possible: without the c = 0 arm there is nothing to compare the correlated fit
# against on this dataset.
EST_C    <- as.integer(Sys.getenv("ESTIMATE_C", "1"))
# The Stan model ships inside the ch2sim directory, so it is located through
# system.file() rather than a path relative to the working directory.
# MODEL_STAN overrides it.
STAN <- Sys.getenv("MODEL_STAN", "")
if (!nzchar(STAN)) {
  STAN <- system.file("extdata", "model_ch2.stan", package = "ch2sim")
}

ts  <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")
say <- function(...) cat(sprintf("[%s][%s] ", ts(), TAG), ..., "\n", sep = "")
safe <- function(label, expr) tryCatch(expr, error = function(e) {
  say("!! '", label, "' failed: ", conditionMessage(e),
      "  (fit already saved; continuing)"); invisible(NULL) })

say("start | data=", DATA, " chains=", NCHAIN, " warmup=", WARMUP,
    " samp=", SAMP, " adapt=", ADAPT, " max_td=", MAXTD)

# serodynamics supplies make_corr_curve_params(), sim_case_data() and
# sim_obs_times(); the Chapter 2 functions (prep_ch2_standata,
# run_mod_stan_ch2, scenario_truth, ...) live in this directory, which is a
# small package of its own so that both can be loaded rather than sourced.
suppressMessages(devtools::load_all(PKG_DIR))
suppressMessages(devtools::load_all(CH2_DIR))
stopifnot(file.exists(DATA), file.exists(STAN))

dat <- readRDS(DATA)
isos <- sort(unique(dat$antigen_iso))
say("subjects=", length(unique(dat$id)), " obs=", nrow(dat),
    " antigen_iso=", paste(isos, collapse = ","))
if (length(isos) != 2L) stop("expected exactly 2 antigen_iso, got ", length(isos))
say("columns: ", paste(names(dat), collapse = ", "))

# prep_ch2_standata() filters on `isos`, which defaults to the typhoid antigen
# names c("HlyE_IgG", "HlyE_IgA"). Shigella biomarkers are named differently, so
# the default silently removes every row and the function then fails on an empty
# frame. The isotype labels present in the data are passed explicitly instead.
# .ch2_cols() reads the column names from attributes that as_case_data() sets,
# and falls back to the typhoid-study defaults (dayssincefeveronset, result)
# when those attributes are absent. Data loaded from disk carries no such
# attributes, so rather than depend on them, the columns are renamed to whatever
# .ch2_cols() actually resolved.
say("resolving columns via .ch2_cols()")
cols <- .ch2_cols(dat)
say("  wants: id=", cols$id, " time=", cols$time, " bio=", cols$bio,
    " value=", cols$value)

OUR <- c(id = "id", time = "timeindays", bio = "antigen_iso", value = "value")
for (role in names(OUR)) {
  from <- OUR[[role]]; to <- cols[[role]]
  if (identical(from, to)) next
  if (from %in% names(dat) && !(to %in% names(dat))) {
    names(dat)[names(dat) == from] <- to
    say("  renamed ", from, " -> ", to)
  }
}
missing <- vapply(c("id", "time", "bio", "value"),
                  function(nm) !cols[[nm]] %in% names(dat), logical(1))
if (any(missing)) {
  stop("still missing: ",
       paste(unlist(cols[c("id", "time", "bio", "value")][missing]),
             collapse = ", "),
       " | columns present: ", paste(names(dat), collapse = ", "))
}
say("  columns now: ", paste(names(dat), collapse = ", "))

# fail here, cheaply, rather than after the model has compiled
sd_check <- tryCatch(prep_ch2_standata(dat, isos = isos),
                     error = function(e) { say("!! prep_ch2_standata failed: ",
                       conditionMessage(e)); NULL })
if (is.null(sd_check)) {
  say("Data rejected by prep_ch2_standata(). Columns: ",
      paste(names(dat), collapse = ", "))
  quit(status = 1)
}
say("stan data prepared | nsubj=", sd_check$nsubj,
    " max_nsmpl=", sd_check$max_nsmpl,
    " visits/subject: ", paste(range(sd_check$nsmpl), collapse = "-"))
if (sd_check$nsubj < length(unique(dat$id))) {
  say("NOTE: ", length(unique(dat$id)) - sd_check$nsubj,
      " subjects dropped (fewer than 2 visits with both isotypes)")
}

say("estimate_c = ", EST_C,
    if (EST_C == 0L) "  (Chapter 1 equivalent: all cross-covariances zero)" else "")
fit_args <- list(dat, STAN, estimate_c = EST_C,
                 nchain = NCHAIN, parallel_chains = NCHAIN,
                 nadapt = WARMUP, niter = SAMP,
                 adapt_delta = ADAPT, max_treedepth = MAXTD, seed = SEED)
if (nzchar(INIT)) {
  fit_args$init <- as.numeric(INIT)
  say("init width = ", INIT)
}
if (FIX_C1 == 1L) {
  if ("fix_c1" %in% names(formals(run_mod_stan_ch2))) {
    fit_args$fix_c1 <- TRUE
    say("FIX_C1 -- baseline cross-covariance held at zero")
  } else {
    say("!! FIX_C1 requested but run_mod_stan_ch2() has no fix_c1 argument.")
    say("   The Stan model needs a flag that zeroes c[1]; see the note in")
    say("   shigella_결과분석.md section 4. Continuing with c[1] free.")
  }
}
if ("isos" %in% names(formals(run_mod_stan_ch2))) {
  fit_args$isos <- isos
  say("passing isos to run_mod_stan_ch2()")
} else {
  # No way to forward the labels, so rename them to the defaults the helper
  # filters on. The mapping is recorded in the result so the output can be read
  # back in terms of the real biomarkers.
  say("run_mod_stan_ch2() has no isos argument; relabelling to the defaults")
  default_isos <- eval(formals(prep_ch2_standata)$isos)
  # Pair the labels by isotype, not by position. `isos` is sorted alphabetically
  # (IgA before IgG) while the defaults are written IgG first, so a positional
  # map silently swaps the two isotypes: the model would fit IgA data under the
  # IgG parameters and every marginal estimate would be mislabelled.
  suffix_of <- function(x) sub("^.*_", "", x)
  ours <- suffix_of(isos)
  theirs <- suffix_of(default_isos)
  if (!setequal(ours, theirs)) {
    stop("cannot match isotypes: data has ", paste(ours, collapse = "/"),
         " but the defaults are ", paste(theirs, collapse = "/"),
         ". Rename the antigen_iso values so the isotype suffixes agree.")
  }
  relabel <- stats::setNames(default_isos[match(ours, theirs)], isos)
  say("  ", paste(sprintf("%s -> %s", names(relabel), relabel), collapse = " | "))
  stopifnot(identical(suffix_of(names(relabel)), suffix_of(unname(relabel))))
  dat[[cols$bio]] <- unname(relabel[as.character(dat[[cols$bio]])])
  fit_args[[1]] <- dat
  # keep the mapping so results can be read back in terms of the real biomarkers
  ISO_MAP <- relabel
}

t0  <- Sys.time()
fit <- do.call(run_mod_stan_ch2, fit_args)
mins <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
say("SAMPLING DONE in ", sprintf("%.1f", mins), " min -- persisting")

csv_dir <- sprintf("csv_%s", TAG); dir.create(csv_dir, showWarnings = FALSE)
safe("copy csv", { file.copy(fit$output_files(), csv_dir, overwrite = TRUE)
  say("csv preserved -> ", csv_dir) })
if (SAVE_FIT == 1L) {
  safe("save_object", { fit$save_object(sprintf("fit_%s.rds", TAG))
    say("saved fit_", TAG, ".rds") })
}

sm <- safe("summary", fit$summary(c("mu_par", "sd_G", "sd_A", "c",
                                    "prec_logy", "cross_corr")))
ds <- safe("diagnostics", fit$diagnostic_summary())
saveRDS(list(tag = TAG, data = DATA, summary = sm, diagnostics = ds,
             minutes = mins, n_subj = sd_check$nsubj, n_obs = nrow(dat),
             antigen_isos = isos, estimate_c = EST_C,
             iso_map = if (exists("ISO_MAP")) ISO_MAP else NULL,
             settings = list(nchain = NCHAIN, warmup = WARMUP, samp = SAMP,
                             adapt_delta = ADAPT, max_td = MAXTD, seed = SEED)),
        sprintf("res_%s.rds", TAG))
say("saved res_", TAG, ".rds  <-- results are safe")

safe("convergence", {
  say("max R-hat = ", sprintf("%.4f", max(sm$rhat, na.rm = TRUE)),
      " | min ESS bulk = ", round(min(sm$ess_bulk, na.rm = TRUE)))
  if (!is.null(ds)) {
    say("divergent = ", sum(ds$num_divergent),
        " | treedepth-saturated = ", sum(ds$num_max_treedepth),
        " / ", NCHAIN * SAMP,
        " | ebfmi ", sprintf("%.3f", min(ds$ebfmi)), "-",
        sprintf("%.3f", max(ds$ebfmi)))
  }
})

if (EST_C == 0L) {
  say("estimate_c = 0, so there are no cross-correlations to report")
} else safe("cross_corr", {
  say("=== cross-biomarker correlations ===")
  if (exists("ISO_MAP")) {
    say("  model slot 1 = ", names(ISO_MAP)[ISO_MAP == "HlyE_IgG"],
        " | slot 2 = ", names(ISO_MAP)[ISO_MAP == "HlyE_IgA"])
  } else {
    say("  ", isos[1], " vs ", isos[2])
  }
  cc <- fit$summary("cross_corr")
  cc$param <- c("baseline", "peak", "peak-time", "decay-rate", "decay-shape")
  cc$excludes_zero <- (cc$q5 > 0) | (cc$q95 < 0)
  print(as.data.frame(cc[, c("param", "mean", "q5", "q95", "rhat",
                             "ess_bulk", "excludes_zero")]), row.names = FALSE)
  say(sum(cc$excludes_zero), " of 5 correlations exclude zero")
  r <- readRDS(sprintf("res_%s.rds", TAG)); r$cross_corr <- cc
  saveRDS(r, sprintf("res_%s.rds", TAG))
})

safe("prec_logy", { say("=== measurement precision ==="); print(fit$summary("prec_logy")) })

# A single stuck chain, or a split between posterior modes, both show up as a
# large R-hat; they need different responses, so separate them here rather than
# after the fact.
safe("per-chain modes", {
  say("=== per-chain diagnosis ===")
  dr <- fit$draws(c("lp__", "cross_corr"))
  nch <- dim(dr)[2]
  lp <- apply(dr[, , "lp__"], 2, mean)
  say("chain lp means: ", paste(sprintf("%.1f", lp), collapse = " "))
  stuck <- which(lp < median(lp) - 50)
  if (length(stuck)) {
    say("STUCK chains (lp more than 50 below median): ",
        paste(stuck, collapse = ", "), " -- discard these")
  }
  cc1 <- apply(dr[, , "cross_corr[1]"], 2, mean)
  say("chain cross_corr[1] means: ", paste(sprintf("%+.3f", cc1), collapse = " "))
  ok <- setdiff(seq_len(nch), stuck)
  if (length(ok) > 1 && diff(range(cc1[ok])) > 0.5) {
    say("MULTIMODAL: cross_corr[1] splits across chains by ",
        sprintf("%.2f", diff(range(cc1[ok]))),
        " -- report modes separately, do not average")
  }
  r <- readRDS(sprintf("res_%s.rds", TAG))
  r$chain_lp <- lp; r$chain_cc1 <- cc1; r$stuck_chains <- stuck
  saveRDS(r, sprintf("res_%s.rds", TAG))
})
say("DONE")
