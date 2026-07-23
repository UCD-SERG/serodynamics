#!/usr/bin/env Rscript
# =====================================================================
# extract_fit_ch2_targets.R
#
# Pull from the fitted Chapter-2 model on nepal_sees everything Method A needs:
#   (1) mu_par      -- population means, MODEL scale (slot 4 = log_k, NOT log_alpha)
#   (2) Sigma_G, Sigma_A -- the FULL 5x5 within-biomarker covariances
#                           (reconstructed per draw as Sigma = L_full L_full')
#   (3) cross_corr  -- what a REALISTIC rho actually looks like
#   (4) prec_logy   -- measurement error (the noise sim_case_data currently omits)
#
# Then check which rho vectors are even ADMISSIBLE (joint covariance positive
# definite) given the real Sigma_G / Sigma_A, using the SAME construction as
# model_ch2.stan:  B = diag(c) inv(L_G)' ,  L_full = [[L_G,0],[B,L_Acond]]
#
# RUN:
#   FIT_PATH=~/path/to/fit_ch2.rds Rscript extract_fit_ch2_targets.R
# OUTPUT:
#   - printed summary  (copy the whole thing back to Claude)
#   - ch2_truth_targets.rds  (mu, Sigma_G, Sigma_A, prec_logy, cross_corr)
# =====================================================================

FIT_PATH <- Sys.getenv("FIT_PATH", "fit_ch2.rds")
P <- 5L; Q <- 10L

cat("==========================================================\n")
cat(" extract_fit_ch2_targets.R\n")
cat(" fit:", FIT_PATH, "\n")
cat("==========================================================\n\n")

if (!file.exists(FIT_PATH)) {
  stop("fit file not found: ", FIT_PATH,
       "\n  -> set FIT_PATH, e.g. FIT_PATH=~/'chapter 2 work'/serodynamics/ch2_nepal/fit_ch2.rds")
}
fit <- readRDS(FIT_PATH)

# ---- draws (cmdstanr objects saved with plain saveRDS may have lost their CSVs) ----
dm <- tryCatch({
  posterior::as_draws_matrix(fit$draws(c("mu_par", "L_full", "prec_logy", "cross_corr")))
}, error = function(e) {
  cat("\n[!] Could not read draws from this object.\n")
  cat("    Message:", conditionMessage(e), "\n")
  cat("    Two common causes:\n")
  cat("      (a) saved with saveRDS() instead of fit$save_object() -> CSV link lost\n")
  cat("      (b) variable name typo. NOTE: there is NO variable called 'Sigma' in\n")
  cat("          model_ch2.stan (it is a local 'Sig' inside generated quantities),\n")
  cat("          which is why fit$summary(c(...,'Sigma',...)) failed.\n")
  cat("    Available variables:\n")
  print(tryCatch(fit$metadata()$stan_variables, error = function(e2) "unavailable"))
  stop("stopping.")
})
nd <- nrow(dm)
cat("draws:", nd, "\n\n")

# ---- (1) population means, model scale ----
mu_G <- colMeans(dm[, sprintf("mu_par[1,%d]", 1:P), drop = FALSE])
mu_A <- colMeans(dm[, sprintf("mu_par[2,%d]", 1:P), drop = FALSE])
names(mu_G) <- names(mu_A) <- c("log_y0", "log_y1y0", "log_t1", "log_k", "log_shape1")

# ---- (2) Sigma = mean over draws of L_full L_full' ----
Lnames <- as.vector(outer(1:Q, 1:Q, function(i, j) sprintf("L_full[%d,%d]", i, j)))
Sig <- matrix(0, Q, Q)
for (d in seq_len(nd)) {
  L <- matrix(dm[d, Lnames], Q, Q)     # column-major fill matches L_full[i,j]
  Sig <- Sig + L %*% t(L)
}
Sig <- Sig / nd
Sigma_G <- Sig[1:P, 1:P]
Sigma_A <- Sig[(P + 1):Q, (P + 1):Q]
Sigma_C <- Sig[1:P, (P + 1):Q]         # should be ~diagonal by construction
dimnames(Sigma_G) <- dimnames(Sigma_A) <- list(names(mu_G), names(mu_G))

sd_G <- sqrt(diag(Sigma_G)); sd_A <- sqrt(diag(Sigma_A))
cor_G <- cov2cor(Sigma_G);   cor_A <- cov2cor(Sigma_A)

# ---- (3)(4) cross_corr and measurement error ----
cc_hat <- colMeans(dm[, sprintf("cross_corr[%d]", 1:P), drop = FALSE])
pl_hat <- colMeans(dm[, sprintf("prec_logy[%d]", 1:2), drop = FALSE])
sd_meas <- 1 / sqrt(pl_hat)

# =====================================================================
# PRINT (copy everything below back to Claude)
# =====================================================================
fmt <- function(x, d = 3) formatC(x, format = "f", digits = d)

cat("---------- (1) mu_par  [MODEL scale: slot4 = log_k] ----------\n")
print(round(rbind(IgG = mu_G, IgA = mu_A), 4))

cat("\n---------- (2a) within-biomarker SD ----------\n")
print(round(rbind(IgG = sd_G, IgA = sd_A), 4))

cat("\n---------- (2b) within-IgG correlation (the g's) ----------\n")
print(round(cor_G, 3))
cat("\n---------- (2c) within-IgA correlation (the a's) ----------\n")
print(round(cor_A, 3))

cat("\n>> KEY: if these off-diagonals are far from 0, then a simulation truth with\n")
cat(">> DIAGONAL within-blocks (what make_corr_curve_params currently builds) is\n")
cat(">> structurally different from the model. max |off-diag|:  IgG =",
    fmt(max(abs(cor_G[upper.tri(cor_G)]))), " IgA =",
    fmt(max(abs(cor_A[upper.tri(cor_A)]))), "\n")

cat("\n---------- (3) fitted cross_corr = a REALISTIC rho ----------\n")
print(round(setNames(cc_hat, names(mu_G)), 4))

cat("\n---------- (4) measurement error (MISSING from sim_case_data) ----------\n")
cat("prec_logy (posterior mean):", fmt(pl_hat, 2), "\n")
cat("implied sd on log scale   :", fmt(sd_meas, 4), "\n")
cat(">> sim_case_data computes value = ab(...) with NO noise. The models\n")
cat(">> (model.jags line 54, model_ch2.stan line 110) BOTH have this noise term.\n")

# =====================================================================
# ADMISSIBILITY: which rho vectors give a positive-definite joint covariance?
# Uses the SAME construction as model_ch2.stan.
# =====================================================================
admiss <- function(rho, SG = Sigma_G, SA = Sigma_A, tol = 1e-10) {
  cvec <- rho * sqrt(diag(SG)) * sqrt(diag(SA))
  L_G  <- t(chol(SG))                                  # lower: L_G L_G' = SG
  B    <- diag(cvec, nrow = length(cvec)) %*% t(solve(L_G))   # diag(c) inv(L_G)'
  R    <- SA - B %*% t(B)
  ev   <- eigen((R + t(R)) / 2, symmetric = TRUE, only.values = TRUE)$values
  list(ok = min(ev) > tol, min_eig = min(ev))
}

max_scale <- function(rho) {                            # largest s with s*rho admissible
  if (all(rho == 0)) return(Inf)
  hi <- 1 / max(abs(rho))                               # keep |s*rho| <= 1
  if (admiss(rho * hi)$ok) return(hi)
  lo <- 0
  for (i in 1:40) { mid <- (lo + hi) / 2
    if (admiss(rho * mid)$ok) lo <- mid else hi <- mid }
  lo
}

cands <- list(
  "null           " = rep(0, P),
  "OLD medium     " = c(0, 0.6, 0.87, 0.76, 0.35),      # what we have been simulating
  "fitted (real)  " = as.numeric(cc_hat),
  "uniform 0.2    " = rep(0.2, P),
  "uniform 0.4    " = rep(0.4, P),
  "uniform 0.6    " = rep(0.6, P),
  "uniform 0.8    " = rep(0.8, P)
)

cat("\n---------- (5) ADMISSIBILITY of candidate rho (PD of joint Sigma) ----------\n")
cat(sprintf("%-16s %-8s %12s %10s\n", "rho", "PD ok?", "min eigen", "max scale"))
for (nm in names(cands)) {
  r <- cands[[nm]]; a <- admiss(r); ms <- max_scale(r)
  cat(sprintf("%-16s %-8s %12s %10s\n", nm,
              if (a$ok) "YES" else "** NO **",
              fmt(a$min_eig, 6),
              if (is.infinite(ms)) "-" else fmt(ms, 3)))
}
cat("\n>> 'max scale' = largest s such that s*rho is still admissible.\n")
cat(">> If OLD medium is NOT PD, the scenario we have been simulating cannot\n")
cat(">> exist under the real within-biomarker covariance.\n")

saveRDS(list(mu_G = mu_G, mu_A = mu_A, Sigma_G = Sigma_G, Sigma_A = Sigma_A,
             Sigma_C = Sigma_C, cross_corr = cc_hat, prec_logy = pl_hat,
             sd_meas = sd_meas, n_draws = nd, fit_path = FIT_PATH),
        "ch2_truth_targets.rds")
cat("\n[saved] ch2_truth_targets.rds\n")
cat("==========================================================\n")
