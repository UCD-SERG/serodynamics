# =====================================================================
# stan_ch2_functions.R  --  SELF-CONTAINED Chapter 2 Stan plumbing (no serodynamics/serocalculator
# export dependencies). Builds the branch's padded 3D Stan-data layout and the per-antigen
# inverse-Wishart priors directly in base R, so it works regardless of the installed package version.
#   - prep_ch2_standata(): paired-visit filter + padded arrays (mirrors prep_data_stan output).
#   - prep_ch2_priors():   per-antigen IW priors + cross-cov + log_alpha->log_k conversion.
#   - run_mod_stan_ch2():  assemble stan_data, compile model_ch2.stan, fit ONE model.
# nepal_sees column names are read from case_data attributes if present, else nepal defaults.
# =====================================================================

# ---- resolve the 4 key columns (attributes if present, else nepal_sees defaults) ----
.ch2_cols <- function(df) {
  nm <- names(df)
  bio  <- attr(df, "biomarker_var"); if (is.null(bio)  || !bio  %in% nm) bio  <- "antigen_iso"
  tim  <- attr(df, "timeindays");    if (is.null(tim)  || !tim  %in% nm) tim  <- "dayssincefeveronset"
  val  <- attr(df, "value_var");     if (is.null(val)  || !val  %in% nm) val  <- "result"
  idv  <- attr(df, "id_var");        if (is.null(idv)  || !idv  %in% nm) idv  <- if ("id" %in% nm) "id" else "person_id"
  list(id = idv, time = tim, value = val, bio = bio)
}

# ---- data: paired-visit filter + padded 3D arrays (branch prep_data_stan layout) ----
prep_ch2_standata <- function(df, min_visits = 2L, isos = c("HlyE_IgG", "HlyE_IgA")) {
  cols <- .ch2_cols(df)
  d <- as.data.frame(df)
  d <- d[!is.na(d[[cols$value]]) & d[[cols$value]] > 0, , drop = FALSE]      # positive values only
  d <- d[d[[cols$bio]] %in% isos, , drop = FALSE]
  key <- interaction(d[[cols$id]], d[[cols$time]], drop = TRUE)
  # paired visits: both antigens present at this (id, time)
  nab <- tapply(d[[cols$bio]], key, function(x) length(unique(x)))
  d <- d[nab[as.character(key)] == 2L, , drop = FALSE]
  # subjects with >= min_visits paired time points
  vpt <- tapply(d[[cols$time]], d[[cols$id]], function(x) length(unique(x)))
  keep_ids <- names(vpt)[vpt >= min_visits]
  d <- d[d[[cols$id]] %in% keep_ids, , drop = FALSE]

  ids <- sort(unique(d[[cols$id]]))
  nsubj <- length(ids)
  visit_days <- lapply(ids, function(s) sort(unique(d[[cols$time]][d[[cols$id]] == s])))
  nsmpl <- vapply(visit_days, length, integer(1))
  max_nsmpl <- max(nsmpl)
  smpl_t <- matrix(0, nsubj, max_nsmpl)
  logy   <- array(0, dim = c(nsubj, max_nsmpl, length(isos)))
  for (si in seq_along(ids)) {
    s <- ids[si]; days <- visit_days[[si]]
    for (oi in seq_along(days)) {
      smpl_t[si, oi] <- days[oi]
      for (ai in seq_along(isos)) {
        sel <- d[[cols$id]] == s & d[[cols$time]] == days[oi] & d[[cols$bio]] == isos[ai]
        logy[si, oi, ai] <- log(d[[cols$value]][sel][1])
      }
    }
  }
  list(nsubj = nsubj, n_antigen_isos = length(isos), n_params = 5L,
       nsmpl = as.integer(nsmpl), max_nsmpl = as.integer(max_nsmpl),
       smpl_t = smpl_t, logy = logy, .ids = ids, .isos = isos)
}

# ---- priors: per-antigen IW + cross-cov + log_k conversion of the decay slot of mu_hyp ----
prep_ch2_priors <- function(n_antigen_isos = 2L,
                            mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
                            prec_hyp_param = c(1.0, 1/9, 1.0, 1/9, 1.0),
                            omega_param = c(1.0, 50.0, 1.0, 10.0, 1.0),
                            wishdf_param = 20,
                            prec_logy_hyp_param = c(4.0, 1.0),
                            c_prior_sd = 1.0, estimate_c = 1L) {
  p <- 5L
  mu_hyp <- array(NA_real_, dim = c(n_antigen_isos, p))
  prec_hyp <- array(NA_real_, dim = c(n_antigen_isos, p, p))
  omega <- array(NA_real_, dim = c(n_antigen_isos, p, p))
  wishdf <- rep(as.numeric(wishdf_param), n_antigen_isos)
  prec_logy_hyp <- array(NA_real_, dim = c(n_antigen_isos, 2))
  for (k in seq_len(n_antigen_isos)) {
    mh <- mu_hyp_param
    log_y1 <- log(exp(mh[1]) + exp(mh[2])); a <- exp(mh[5])
    mh[4] <- mh[4] + a * log_y1                          # log_alpha -> log_k
    mu_hyp[k, ] <- mh
    prec_hyp[k, , ] <- diag(prec_hyp_param)
    omega[k, , ] <- diag(omega_param)
    prec_logy_hyp[k, ] <- prec_logy_hyp_param
  }
  list(mu_hyp = mu_hyp, prec_hyp = prec_hyp, omega = omega, wishdf = wishdf,
       prec_logy_hyp = prec_logy_hyp, c_prior_sd = as.numeric(c_prior_sd),
       estimate_c = as.integer(estimate_c))
}

run_mod_stan_ch2 <- function(data, file_mod = "model_ch2.stan", estimate_c = 1L,
                             nchain = 8, nadapt = 2000, niter = 1000, parallel_chains = nchain,
                             adapt_delta = 0.99, max_treedepth = 14, c_prior_sd = 1.0,
                             init = 0.3, seed = 1, threads_per_chain = NULL, min_visits = 2L,
                             mu_hyp_param = c(1.0, 7.0, 1.0, -4.0, -1.0),
                             compile_methods = FALSE, ...) {
  if (!requireNamespace("cmdstanr", quietly = TRUE)) stop("cmdstanr required.")
  stopifnot(file.exists(file_mod))
  sd_list <- prep_ch2_standata(data, min_visits = min_visits)
  if (sd_list$n_antigen_isos != 2) stop("Chapter 2 requires exactly 2 antigens.")
  pri <- prep_ch2_priors(n_antigen_isos = sd_list$n_antigen_isos, mu_hyp_param = mu_hyp_param,
                         c_prior_sd = c_prior_sd, estimate_c = estimate_c)
  sd_clean <- sd_list[setdiff(names(sd_list), c(".ids", ".isos"))]
  stan_data <- c(sd_clean, pri)
  cpp <- if (!is.null(threads_per_chain)) list(stan_threads = TRUE) else list()

  # --- compile in an EXECUTABLE, space-free dir (working dir may be noexec, e.g. /export/home) ---
  # error 13 (Permission denied) when running the compiled 'model_ch2' means the exe's directory is
  # mounted noexec. Copy the .stan to CMDSTAN_EXEC_DIR (default a /tmp subdir) and compile there.
  exec_dir <- Sys.getenv("CMDSTAN_EXEC_DIR", "")
  if (!nzchar(exec_dir)) exec_dir <- file.path(tempdir(), "ch2_exe")
  dir.create(exec_dir, showWarnings = FALSE, recursive = TRUE)
  stan_local <- file.path(exec_dir, basename(file_mod))
  if (!file.exists(stan_local) ||
        !isTRUE(tools::md5sum(stan_local) == tools::md5sum(file_mod))) {
    file.copy(file_mod, stan_local, overwrite = TRUE)
  }
  # compile_methods=TRUE exposes log_prob/grad_log_prob so LOO moment-matching can fix high Pareto k.
  # It uses Rcpp sourceCpp, which on some systems fails to link TBB (-ltbb not found). Make it
  # FAIL-SAFE: if the methods build fails, fall back to a normal compile so sampling still proceeds.
  methods_ok <- FALSE
  if (isTRUE(compile_methods)) {
    mod <- tryCatch({
      m <- cmdstanr::cmdstan_model(stan_local, cpp_options = cpp,
                                   compile_model_methods = TRUE, force_recompile = TRUE)
      methods_ok <- TRUE; m
    }, error = function(e) {
      message("[run_mod_stan_ch2] compile_model_methods failed (", conditionMessage(e),
              "); compiling WITHOUT methods -> LOO will use plain PSIS-LOO.")
      cmdstanr::cmdstan_model(stan_local, cpp_options = cpp)
    })
  } else {
    mod <- cmdstanr::cmdstan_model(stan_local, cpp_options = cpp)
  }
  fit <- mod$sample(data = stan_data, chains = nchain, parallel_chains = parallel_chains,
                    iter_warmup = nadapt, iter_sampling = niter, adapt_delta = adapt_delta,
                    max_treedepth = max_treedepth, init = init, seed = seed, refresh = 250,
                    threads_per_chain = threads_per_chain)
  if (isTRUE(compile_methods) && methods_ok) {
    ok <- tryCatch({ fit$init_model_methods(verbose = FALSE); TRUE }, error = function(e) FALSE)
    attr(fit, "methods_ok") <- ok
  } else attr(fit, "methods_ok") <- FALSE
  attr(fit, "n_subjects_kept") <- sd_list$nsubj
  fit
}
