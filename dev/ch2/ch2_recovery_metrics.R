#!/usr/bin/env Rscript
# =====================================================================
# ch2_recovery_metrics.R  --  aggregate one scenario's seeds into Ezra's metrics:
#   bias, MSE, posterior variance, coverage -- per parameter, per model (Ch1/Ch2).
#   Truth is recomputed EXACTLY from the same rho/mu/sd inputs (scenario_truth),
#   so it is independent of any fit.
#
#   SCENARIO=medium RHO="0,0.6,0.87,0.76,0.35" Rscript ch2_recovery_metrics.R
#   (mu/sd default to the same values as ch2_sim_one.R; override via env to match.)
# =====================================================================
source("ch2_sim_functions.R")

SCEN <- Sys.getenv("SCENARIO", "medium")
RHO  <- as.numeric(strsplit(Sys.getenv("RHO", "0,0.6,0.87,0.76,0.35"), ",")[[1]])
mu_G <- as.numeric(strsplit(Sys.getenv("MU_G", "0.8,5.1,2.2,-7.1,-0.9"), ",")[[1]])
mu_A <- as.numeric(strsplit(Sys.getenv("MU_A", "0.7,4.2,1.6,-7.1,-0.4"), ",")[[1]])
sd_G <- as.numeric(strsplit(Sys.getenv("SD_G", "0.3,0.3,0.2,0.5,0.4"), ",")[[1]])
sd_A <- as.numeric(strsplit(Sys.getenv("SD_A", "0.3,0.4,0.3,0.5,0.4"), ",")[[1]])

## ---- exact model-scale truth for this scenario ----
tr <- scenario_truth(mu_G, mu_A, sd_G, sd_A, RHO)
truth_of <- function(kind, antigen, slot) {
  if (kind == "cross_corr") tr$cross_corr[slot]
  else tr$mu_par[if (antigen == "IgG") 1 else 2, slot]
}

## ---- load all seeds for this scenario, both models ----
files <- list.files(pattern = sprintf("^sim_%s_(ch1|ch2)_seed[0-9]+\\.csv$", SCEN))
if (length(files) == 0) stop(sprintf("no sim CSVs found for scenario '%s'", SCEN))
D <- do.call(rbind, lapply(files, read.csv, stringsAsFactors = FALSE))
cat(sprintf("[metrics] scenario=%s: %d rows from %d files; seeds: %s\n",
            SCEN, nrow(D), length(files), paste(sort(unique(D$seed)), collapse=",")))

# --- exclude NON-CONVERGED fits (unreliable CI -> invalid coverage) ---
RHAT_MAX <- as.numeric(Sys.getenv("RHAT_MAX", "1.1"))
if ("max_rhat_fit" %in% names(D)) {
  bad <- unique(D[is.finite(D$max_rhat_fit) & D$max_rhat_fit > RHAT_MAX,
                  c("model","seed","max_rhat_fit")])
  if (nrow(bad)) {
    cat(sprintf("[metrics] EXCLUDING %d non-converged fit(s) (Rhat > %.2f):\n", nrow(bad), RHAT_MAX))
    for (i in seq_len(nrow(bad)))
      cat(sprintf("          %s seed %d (Rhat %.3f)\n", bad$model[i], bad$seed[i], bad$max_rhat_fit[i]))
    D <- D[!(is.finite(D$max_rhat_fit) & D$max_rhat_fit > RHAT_MAX), ]
    cat(sprintf("[metrics] kept seeds -> ch2: %s | ch1: %s\n",
        paste(sort(unique(D$seed[D$model=="ch2"])), collapse=","),
        paste(sort(unique(D$seed[D$model=="ch1"])), collapse=",")))
  }
}

## ---- compute metrics per (kind, antigen, slot, model) ----
grid <- unique(D[, c("kind","antigen","slot","label","model")])
res <- do.call(rbind, lapply(seq_len(nrow(grid)), function(i) {
  g <- grid[i, ]
  sub <- D[D$kind==g$kind & D$antigen==g$antigen & D$slot==g$slot & D$model==g$model, ]
  th <- truth_of(g$kind, g$antigen, g$slot)
  m <- recovery_metrics(sub$mean, sub$q5, sub$q95, sub$sd, th)
  data.frame(scenario = SCEN, kind = g$kind, antigen = g$antigen, slot = g$slot,
             label = g$label, model = g$model, truth = th,
             bias = m["bias"], mse = m["mse"], post_var = m["post_var"],
             coverage = m["coverage"], n_seed = m["n_seed"], row.names = NULL)
}))
res <- res[order(res$kind, res$slot, res$antigen, res$model), ]
out_csv <- sprintf("recovery_metrics_%s.csv", SCEN)
write.csv(res, out_csv, row.names = FALSE)
cat(sprintf("[metrics] wrote %s\n\n", out_csv))

## ---- readable Ch1-vs-Ch2 comparison ----
fmt <- function(x, d=3) formatC(x, format="f", digits=d)
cat("=== CROSS-CORRELATIONS (the key new parameters) ===\n")
cc <- res[res$kind=="cross_corr", ]
for (j in sort(unique(cc$slot))) {
  r1 <- cc[cc$slot==j & cc$model=="ch1", ]; r2 <- cc[cc$slot==j & cc$model=="ch2", ]
  cat(sprintf("  %-11s truth=%+.3f | Ch1 cov=%s bias=%s | Ch2 cov=%s bias=%s mse=%s\n",
              r2$label, r2$truth,
              fmt(r1$coverage,2), fmt(r1$bias), fmt(r2$coverage,2), fmt(r2$bias), fmt(r2$mse)))
}
cat("  -> Ch1 forces c=0: coverage 0% for any nonzero truth; Ch2 should recover (~0.90).\n\n")

cat("=== CURVE PARAMETERS (mu_par): does Ch2 recover better? ===\n")
mp <- res[res$kind=="mu_par", ]
cat(sprintf("  %-4s %-11s %8s | %-18s | %-18s\n","ant","param","truth","Ch1 cov/mse/var","Ch2 cov/mse/var"))
for (i in which(mp$model=="ch2")) {
  r2 <- mp[i, ]; r1 <- mp[mp$antigen==r2$antigen & mp$slot==r2$slot & mp$model=="ch1", ]
  cat(sprintf("  %-4s %-11s %+8.2f | %s/%s/%s | %s/%s/%s\n",
              r2$antigen, r2$label, r2$truth,
              fmt(r1$coverage,2), fmt(r1$mse), fmt(r1$post_var),
              fmt(r2$coverage,2), fmt(r2$mse), fmt(r2$post_var)))
}
cat("  -> look for Ch2 lower MSE / lower post_var (borrowing), coverage near 0.90 both.\n")

## ---- convergence flag ----
bad <- D[is.finite(D$max_rhat_fit) & D$max_rhat_fit > 1.1, c("model","seed","max_rhat_fit")]
if (nrow(bad)) {
  cat(sprintf("\n[WARN] %d fits with max Rhat > 1.1 (consider more warmup/samples):\n", nrow(unique(bad))))
  print(unique(bad))
}
cat("\n[metrics] DONE\n")
