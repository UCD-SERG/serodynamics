#!/usr/bin/env Rscript
# =====================================================================
# make_ch2_shigella_input.R -- carve one antigen's IgG/IgA pair out of the
# SOSAR longitudinal cohort, in the shape the Chapter 2 model consumes.
#
# The Chapter 2 model estimates a cross-biomarker correlation between the IgG
# and IgA responses OF THE SAME PERSON, so both isotypes must come from the same
# subject set. That is a stricter requirement than Chapter 1, which fitted each
# antigen-isotype independently and was free to choose a different subject
# subset for each (Table 2: Sf2a IgA used "Combined flexneri", n = 25, while
# Sf2a IgG used "Serotype-specific", n = 17). For Chapter 2 one subset has to be
# chosen per antigen.
#
# Output columns match what run_mod_stan_ch2() expects from sim_case_data():
#   id, timeindays, antigen_iso, value
#
# SUBJECT SUBSETS
#   overall     all 48 SOSAR subjects. Appropriate for ipaB, a virulence protein
#               conserved across Shigella serotypes, so every infected person
#               mounts a response.
#   serotype    only subjects whose infecting serotype matches the antigen.
#               Appropriate for the serotype-specific OSP antigens, where
#               subjects infected with a different serotype contribute no signal
#               and would dilute the estimate.
#   flexneri    Sf2a- and Sf3a-infected subjects pooled (n = 25), matching
#               Chapter 1's "Combined flexneri" grouping. Chapter 1 found the
#               Sf2a response fits better on this pooled set than on
#               Sf2a-infected subjects alone, consistent with cross-reactivity
#               between the Sf2a and Sf3a O-antigens. This is the subset to use
#               for a Sf2a run.
#
# USAGE:
#   Rscript make_ch2_shigella_input.R <xlsx> <antigen> <subset>
#   Rscript make_ch2_shigella_input.R data.xlsx ipaB overall
#   Rscript make_ch2_shigella_input.R data.xlsx Sf2a serotype
# =====================================================================
suppressPackageStartupMessages({
  library(readxl); library(dplyr); library(tidyr)
})

args <- commandArgs(TRUE)
xlsx    <- if (length(args) >= 1) args[1] else "3_8_2024_Compiled_Shigella_datav2.xlsx"
antigen <- if (length(args) >= 2) args[2] else "ipaB"
subset  <- if (length(args) >= 3) args[3] else "overall"
stopifnot(file.exists(xlsx), subset %in% c("overall", "serotype", "flexneri"))

ANTIGEN_COL <- c(
  ipaB   = "n_ipab_MFI",
  Sf2a   = "n_sf2aospbsa_MFI",
  Sf3a   = "n_sf3aospbsa_MFI",
  Sf6    = "n_sf6ospbsa_MFI",
  sonnei = "n_sonneiospbsa_MFI"
)
stopifnot(antigen %in% names(ANTIGEN_COL))
value_col <- ANTIGEN_COL[[antigen]]

raw <- readxl::read_excel(xlsx, sheet = "Compiled")
sosar <- raw |> filter(.data$study_name == "SOSAR")
cat("SOSAR rows:", nrow(sosar), "| subjects:", length(unique(sosar$sid)), "\n")

# ---- subject subset --------------------------------------------------------
# Chapter 1's "Combined flexneri" group is n = 25, which is Sf2a (17) + Sf3a (8);
# Sf6 was modelled under "Overall" there and is left out here to match. Set
# FLEXNERI_BROAD=1 to pool every S. flexneri serotype instead (n = 33).
FLEXNERI <- if (nzchar(Sys.getenv("FLEXNERI_BROAD"))) {
  c("Sf2a", "Sf3a", "Sf6", "sf6", "sf1c", "sf-NT")
} else {
  c("Sf2a", "Sf3a")
}
keep_sid <- switch(
  subset,
  overall  = unique(sosar$sid),
  serotype = unique(sosar$sid[sosar$cohort_name == antigen]),
  flexneri = unique(sosar$sid[sosar$cohort_name %in% FLEXNERI])
)
cat("subset '", subset, "' -> ", length(keep_sid), " subjects\n", sep = "")
if (length(keep_sid) < 10) {
  cat("\nWARNING: with fewer than ~10 subjects the 10-dimensional joint\n",
      "covariance is not practically identifiable. Expect the sampler to be\n",
      "driven by the prior rather than the data.\n\n", sep = "")
}

# ---- reshape to case_data --------------------------------------------------
# `Actual day` is the recorded visit day and departs from the nominal timepoint
# (a nominal day 90 visit occurs anywhere from day 92 to day 114), so it is the
# correct time variable for a kinetics model.
dat <- sosar |>
  filter(.data$sid %in% keep_sid) |>
  transmute(
    id = as.character(.data$sid),
    timeindays = suppressWarnings(as.numeric(.data$`Actual day`)),
    antigen_iso = paste(antigen, .data$isotype_name, sep = "_"),
    value = suppressWarnings(as.numeric(.data[[value_col]])),
    serotype = .data$cohort_name
  ) |>
  filter(is.finite(.data$timeindays), is.finite(.data$value), .data$value > 0)

cat("\nrows after cleaning:", nrow(dat), "\n")

# both isotypes must be present for every subject-visit, or the pair is broken
pair_check <- dat |>
  count(.data$id, .data$timeindays, name = "n_iso")
unpaired <- sum(pair_check$n_iso != 2)
cat("subject-visits with both isotypes:", sum(pair_check$n_iso == 2),
    "| unpaired:", unpaired, "\n")
if (unpaired > 0) {
  cat("  dropping unpaired visits -- the cross-correlation needs both isotypes\n")
  ok <- pair_check |> filter(.data$n_iso == 2) |> select("id", "timeindays")
  dat <- dat |> semi_join(ok, by = c("id", "timeindays"))
}

visits <- dat |> distinct(.data$id, .data$timeindays) |> count(.data$id, name = "n_visit")
cat("\nvisits per subject:\n"); print(table(visits$n_visit))
cat("\nobservations:", nrow(dat),
    "| latent parameters:", length(unique(dat$id)) * 10, "\n")
if (nrow(dat) < length(unique(dat$id)) * 10) {
  cat("  fewer observations than latent parameters; the population\n",
      "  distribution carries most of the weight here.\n", sep = "")
}

cat("\nvalue range by isotype:\n")
print(dat |> group_by(.data$antigen_iso) |>
        summarise(n = n(), min = min(.data$value), median = median(.data$value),
                  max = max(.data$value), .groups = "drop"))

cat("\ninfecting serotypes represented:\n")
print(dat |> distinct(.data$id, .data$serotype) |> count(.data$serotype))

out <- dat |> select("id", "timeindays", "antigen_iso", "value")
tag <- sprintf("%s_%s", antigen, subset)
saveRDS(out, sprintf("ch2_input_%s.rds", tag))
write.csv(out, sprintf("ch2_input_%s.csv", tag), row.names = FALSE)
cat("\n[saved] ch2_input_", tag, ".rds  (", nrow(out), " rows, ",
    length(unique(out$id)), " subjects )\n", sep = "")
