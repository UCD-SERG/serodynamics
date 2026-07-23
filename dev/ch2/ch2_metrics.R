#!/usr/bin/env Rscript
# =====================================================================
# ch2_metrics.R -- pool converged seeds into Ezra's four metrics.
#
# Reads every res_*.rds in the working directory (both the original
# res_prod_*.rds and any res_rerun_*.rds), keeps the seeds that converged
# (R-hat < RHAT_MAX, default 1.1), and reports per sample size:
#   bias, MSE, mean posterior variance, and coverage
# for the five cross-biomarker correlations and the ten mu_par means.
# Also writes a coverage/bias figure.
#
#   *"bias and mean square error for the model parameters"*
#   *"the variance of the posterior distributions"*
#   *"coverage, just like you did in chapter one"*
#
# USAGE:
#   Rscript ch2_metrics.R                 # all res_*.rds, R-hat < 1.1
#   RHAT_MAX=1.05 Rscript ch2_metrics.R   # stricter convergence filter
# =====================================================================
HAS_GG <- requireNamespace("ggplot2", quietly = TRUE)

RHAT_MAX <- as.numeric(Sys.getenv("RHAT_MAX", "1.1"))
`%||%` <- function(x, y) if (is.null(x)) y else x
PARAM_LABELS <- c("baseline", "peak", "peak-time", "decay-rate", "decay-shape")

# Results can live in more than one place: the pre-rerun cells were archived in
# their own folder while the reruns land in the working directory. Pass any
# number of directories; with none, the working directory is used.
dirs <- commandArgs(TRUE)
if (!length(dirs)) dirs <- "."
files <- unlist(lapply(dirs, function(d) Sys.glob(file.path(d, "res_*.rds"))))
if (!length(files)) {
  stop("no res_*.rds found in: ", paste(dirs, collapse = ", "))
}
cat("searching:", paste(dirs, collapse = ", "), "\n")

fits <- lapply(files, function(p) {
  r <- try(readRDS(p), silent = TRUE)
  if (inherits(r, "try-error") || is.null(r$summary)) return(NULL)
  r
})
fits <- Filter(Negate(is.null), fits)

# keep converged, de-duplicate by (n, seed) preferring a rerun over the original
key  <- vapply(fits, function(r) sprintf("%d_%d", r$settings$n, r$settings$seed), "")
is_rerun <- grepl("rerun", vapply(fits, function(r) r$tag %||% "", ""))
conv <- vapply(fits, function(r) max(r$summary$rhat, na.rm = TRUE) < RHAT_MAX, TRUE)

ord <- order(key, -as.integer(is_rerun))          # rerun first within a key
seen <- character(0); keep <- logical(length(fits))
for (i in ord) {
  if (!conv[i]) next
  if (key[i] %in% seen) next
  seen <- c(seen, key[i]); keep[i] <- TRUE
}
fits_keep <- fits[keep]

cat("res files:", length(files), "| converged & unique:", length(fits_keep),
    "(R-hat <", RHAT_MAX, ")\n")
by_n <- split(fits_keep, vapply(fits_keep, function(r) r$settings$n, 1))
for (nn in names(by_n)) {
  seeds <- sort(vapply(by_n[[nn]], function(r) r$settings$seed, 1))
  cat("  n =", nn, ":", length(seeds), "seeds ->", paste(seeds, collapse = ","), "\n")
}
cat("\n")

# ---- metrics per sample size -----------------------------------------------
metrics_cross <- function(lst) {
  truth <- lst[[1]]$truth$cross_corr
  mean_mat <- sapply(lst, function(r) r$cross_corr$mean)
  sd_mat   <- sapply(lst, function(r) r$cross_corr$sd)
  cov_mat  <- sapply(lst, function(r) r$cross_corr$covered)
  data.frame(
    param    = PARAM_LABELS,
    truth    = round(truth, 3),
    bias     = round(rowMeans(mean_mat) - truth, 4),
    mse      = round(rowMeans((mean_mat - truth)^2), 4),
    post_var = round(rowMeans(sd_mat^2), 4),
    coverage = rowMeans(cov_mat),
    n_seed   = length(lst)
  )
}

all_cross <- list()
for (nn in names(by_n)) {
  cat("=========== n =", nn, ": cross_corr recovery ===========\n")
  m <- metrics_cross(by_n[[nn]])
  print(m, row.names = FALSE)
  cat("\n")
  m$n <- as.integer(nn)
  all_cross[[nn]] <- m
}
cross_df <- do.call(rbind, all_cross)
write.csv(cross_df, "ch2_metrics_cross_corr.csv", row.names = FALSE)

# ---- coverage + bias figure ------------------------------------------------
if (HAS_GG) {
cross_df$param <- factor(cross_df$param, levels = PARAM_LABELS)
p <- ggplot2::ggplot(cross_df, ggplot2::aes(x = param, y = coverage,
                          colour = factor(n), group = factor(n))) +
  ggplot2::geom_hline(yintercept = 0.9, linetype = "dashed", colour = "grey50") +
  ggplot2::geom_point(size = 3) + ggplot2::geom_line() +
  ggplot2::scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  ggplot2::labs(x = NULL, y = "90% CI coverage", colour = "n",
       title = "Cross-biomarker correlation recovery",
       subtitle = sprintf("converged seeds only (R-hat < %.2f); dashed = nominal 0.9",
                          RHAT_MAX)) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 20, hjust = 1))
ggplot2::ggsave("ch2_coverage.png", p, width = 7, height = 4.5, dpi = 150)
  cat("[saved] ch2_coverage.png\n")
} else {
  cat("(ggplot2 unavailable -- CSV written, figure skipped)\n")
}
cat("[saved] ch2_metrics_cross_corr.csv\n")
