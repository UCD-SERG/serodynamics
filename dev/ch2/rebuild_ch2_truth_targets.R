#!/usr/bin/env Rscript
# =====================================================================
# rebuild_ch2_truth_targets.R
#
# Writes ch2_truth_targets.rds into the current directory, with no binary
# transfer required.
#
# PROVENANCE -- every number below was computed from the posterior draws of
#   ~/"chapter 2 work"/serodynamics/ch2_nepal/trial2/fit_ch2.rds
# (48 chains x 334 samples = 16,032 draws; nepal_sees, 129 paired-visit
# subjects; max R-hat over the extracted quantities = 1.0841, none > 1.1).
#   mu_*    = posterior mean of mu_par[antigen, ]          (MODEL scale, slot 4 = log_k)
#   Sigma_* = posterior mean of L_full L_full', block-split (Sigma_A is the MARGINAL)
#   prec_logy = posterior mean
# Nothing here is rounded for display; values carry 10 significant digits.
#
# RUN:
#   cd ~/"chapter 2 work"/serodynamics/ch2_sim
#   Rscript rebuild_ch2_truth_targets.R
# =====================================================================

PN <- c("log_y0", "log_y1y0", "log_t1", "log_k", "log_shape1")

MU_G <- c(-0.2165615597, 5.231769395, 1.915757259, -4.099265171, -0.3742409888)
MU_A <- c(0.05984672322, 4.333428187, 1.958614018, -2.714890568, 0.3451025325)

SIG_G <- matrix(c(
   0.1142029657,   0.06366749723, -0.05964020412,  0.02967936218, -0.001011414619,
   0.06366749723,  1.307757188,   -0.1023958621,   0.177060244,    0.001840150523,
  -0.05964020412, -0.1023958621,   0.4100682369,  -0.03302863284, -0.001481826302,
   0.02967936218,  0.177060244,   -0.03302863284,  0.7133914662,   0.004021319213,
  -0.001011414619, 0.001840150523,-0.001481826302,  0.004021319213, 0.07483560437),
  5, 5)

SIG_A <- matrix(c(
   0.5996345755,   0.06267685364, -0.1424284466,   0.06578618926, -0.006303770083,
   0.06267685364,  1.834428493,    0.0587653518,   0.297865466,   -0.06316877866,
  -0.1424284466,   0.0587653518,   0.9564471305,   0.04845829219,  0.01082569051,
   0.06578618926,  0.297865466,    0.04845829219,  2.238985738,    0.04058516298,
  -0.006303770083,-0.06316877866,  0.01082569051,  0.04058516298,  0.09062788065),
  5, 5)

CC_MEAN <- c(-0.7648467938, 0.6188408757, 0.8730485653, 0.7531372458,  0.2808526779)
CC_MED  <- c(-0.808226445,  0.623743625,  0.88071912,   0.77084766,    0.3573165)
CC_LO   <- c(-0.919079595,  0.483071669,  0.7840791935, 0.573748397,  -0.435271866)
CC_HI   <- c(-0.6076532135, 0.7368820125, 0.9363539245, 0.8789674155,  0.7635093135)
PREC    <- c(11.9693159, 10.71977321)

names(MU_G) <- names(MU_A) <- PN
dimnames(SIG_G) <- dimnames(SIG_A) <- list(PN, PN)

targets <- list(
  mu_G = MU_G, mu_A = MU_A,
  Sigma_G = SIG_G, Sigma_A = SIG_A,
  cross_corr_mean = CC_MEAN, cross_corr_median = CC_MED,
  cross_corr_lo90 = CC_LO,   cross_corr_hi90 = CC_HI,
  prec_logy = PREC, sd_meas = 1 / sqrt(PREC),
  n_draws = 16032L,
  fit_path = "ch2_nepal/trial2/fit_ch2.rds",
  note = "posterior means from trial2 Ch2 fit on nepal_sees (129 subjects); model scale, slot 4 = log_k"
)

saveRDS(targets, "ch2_truth_targets.rds")

# ---- self-check: values must be usable, not just present -------------------
stopifnot(isSymmetric(unname(SIG_G), tol = 1e-8),
          isSymmetric(unname(SIG_A), tol = 1e-8))
eg <- min(eigen(SIG_G, symmetric = TRUE, only.values = TRUE)$values)
ea <- min(eigen(SIG_A, symmetric = TRUE, only.values = TRUE)$values)
stopifnot(eg > 0, ea > 0)

cat("[saved] ch2_truth_targets.rds\n")
cat("  min eigenvalue  Sigma_G =", format(eg, digits = 4),
    " Sigma_A =", format(ea, digits = 4), " (both must be > 0)\n")
cat("  sd_G =", sprintf("%.4f", sqrt(diag(SIG_G))), "\n")
cat("  sd_A =", sprintf("%.4f", sqrt(diag(SIG_A))), "\n")
cat("  noise_sd (log scale) =", sprintf("%.4f", 1 / sqrt(PREC)), "\n")

# ---- admissibility of the rho we are about to simulate ---------------------
admiss <- function(rho) {
  cv <- rho * sqrt(diag(SIG_G)) * sqrt(diag(SIG_A))
  LG <- t(chol(SIG_G)); B <- diag(cv, 5) %*% t(solve(LG))
  R <- SIG_A - B %*% t(B); R <- (R + t(R)) / 2
  min(eigen(R, symmetric = TRUE, only.values = TRUE)$values)
}
cat("  admissibility min-eigen:  fitted median =", format(admiss(CC_MED), digits = 4),
    " | null =", format(admiss(rep(0, 5)), digits = 4), " (must be > 0)\n")
