#' @title load and format data
#' @description Load and format typhoid case data from a CSV file into a
#' structured list for use with JAGS Bayesian modeling. The function processes
#' longitudinal antibody measurements across multiple biomarkers and visits.
#'
#' @param datapath path to data folder
#' @param datafile data file name
#'
#' @returns a [list] with the following elements:
#' * `smpl.t` = time since symptom/fever onset for each participant,
#' max 7 visits
#' * `logy` = log antibody response at each time-point (max 7)
#' for each of 7 biomarkers for each participant
#' * `ntest` is max number of biomarkers
#' * `nsmpl` = max number of samples per participant
#' * `nsubj` = number of study participants
#' * `ndim` = number of parameters to model(y0, y1, t1, alpha, shape)
#' * `my.hyp`, `prec.hyp`, `omega` and `wishdf`
#' are all parameters to describe the shape of priors
#' for (y0, y1, t1, alpha, shape)
#' @export
#'
load_data <- function(
    datapath = "inst/extdata/",
    datafile = "TypoidCaseData_github_09.30.21.csv") {
  raw <- paste(datapath, datafile, sep = "") |> read.csv(header = TRUE)
  id <- raw$index_id
  age <- raw$age

  hlye_iga <- cbind(
    raw$HlyE_IgA_visit1, raw$HlyE_IgA_visit2,
    raw$HlyE_IgA_visit3, raw$HlyE_IgA_visit4,
    raw$HlyE_IgA_visit5, raw$HlyE_IgA_visit6,
    raw$HlyE_IgA_visit7
  )
  hlye_igg <- cbind(
    raw$HlyE_IgG_visit1, raw$HlyE_IgG_visit2,
    raw$HlyE_IgG_visit3, raw$HlyE_IgG_visit4,
    raw$HlyE_IgG_visit5, raw$HlyE_IgG_visit6,
    raw$HlyE_IgG_visit7
  )
  lps_iga <- cbind(
    raw$LPS_IgA_visit1, raw$LPS_IgA_visit2,
    raw$LPS_IgA_visit3, raw$LPS_IgA_visit4,
    raw$LPS_IgA_visit5, raw$LPS_IgA_visit6,
    raw$LPS_IgA_visit7
  )
  lps_igg <- cbind(
    raw$LPS_IgG_visit1, raw$LPS_IgG_visit2,
    raw$LPS_IgG_visit3, raw$LPS_IgG_visit4,
    raw$LPS_IgG_visit5, raw$LPS_IgG_visit6,
    raw$LPS_IgG_visit7
  )
  mp_iga <- cbind(
    raw$MP_IgA_visit1, raw$MP_IgA_visit2,
    raw$MP_IgA_visit3, raw$MP_IgA_visit4,
    raw$MP_IgA_visit5, raw$MP_IgA_visit6,
    raw$MP_IgA_visit7
  )
  mp_igg <- cbind(
    raw$MP_IgG_visit1, raw$MP_IgG_visit2,
    raw$MP_IgG_visit3, raw$MP_IgG_visit4,
    raw$MP_IgG_visit5, raw$MP_IgG_visit6,
    raw$MP_IgG_visit7
  )
  vi_igg <- cbind(
    raw$Vi_IgG_visit1, raw$Vi_IgG_visit2,
    raw$Vi_IgG_visit3, raw$Vi_IgG_visit4,
    raw$Vi_IgG_visit5, raw$Vi_IgG_visit6,
    raw$Vi_IgG_visit7
  )
  visit_t <- cbind(
    raw$TimeInDays_visit1, raw$TimeInDays_visit2,
    raw$TimeInDays_visit3, raw$TimeInDays_visit4,
    raw$TimeInDays_visit5, raw$TimeInDays_visit6,
    raw$TimeInDays_visit7
  )

  nsubj <- length(id)

  # define this from the data levels(antigen_iso)
  n_biomarkers <- 7

  # again defined from data
  maxsmpl <- 7 # maximum nr. samples per subject

  nsmpl <- rep(NA, nsubj + 1)
  sample_times <- array(NA, dim = c(nsubj + 1, maxsmpl))
  sample_y_values <- array(NA, dim = c(nsubj + 1, maxsmpl, n_biomarkers))
  indx <- array(NA, dim = c(nsubj + 1, maxsmpl))
  for (k.subj in 1:nsubj) {
    exst <- sort(which(!is.na(visit_t[k.subj, ])))
    nsmpl[k.subj] <- length(exst)
    indx[k.subj, 1:nsmpl[k.subj]] <- exst
    sample_times[k.subj, 1:nsmpl[k.subj]] <- visit_t[k.subj, exst]
    sample_y_values[k.subj, 1:nsmpl[k.subj], 1] <- hlye_iga[k.subj, exst]
    sample_y_values[k.subj, 1:nsmpl[k.subj], 2] <- hlye_igg[k.subj, exst]
    sample_y_values[k.subj, 1:nsmpl[k.subj], 3] <- lps_iga[k.subj, exst]
    sample_y_values[k.subj, 1:nsmpl[k.subj], 4] <- lps_igg[k.subj, exst]
    sample_y_values[k.subj, 1:nsmpl[k.subj], 5] <- mp_iga[k.subj, exst]
    sample_y_values[k.subj, 1:nsmpl[k.subj], 6] <- mp_igg[k.subj, exst]
    sample_y_values[k.subj, 1:nsmpl[k.subj], 7] <- vi_igg[k.subj, exst]
  }
  nsmpl[nsubj + 1] <- 3
  sample_times[nsubj + 1, ] <- c(5, 30, 90, NA, NA, NA, NA)
  age <- c(age, 10) # just made this up
  sample_y_values[sample_y_values == 0] <- 0.01 # remove y=0
  logy <- log(sample_y_values)

  npar <- 5 # y0, y1, t1, alpha, shape
  ndim <- npar # size of cov mat
  mu_hyp <- array(NA, dim = c(n_biomarkers, ndim))
  prec_hyp <- array(NA, dim = c(n_biomarkers, ndim, ndim))
  omega <- array(NA, dim = c(n_biomarkers, ndim, ndim))
  wishdf <- rep(NA, n_biomarkers)
  prec_logy_hyp <- array(NA, dim = c(n_biomarkers, 2))
  #  will contain logarithms of log(c(y0,  y1,    t1,  alpha, shape-1))
  for (cur_biomarker in 1:n_biomarkers) {
    mu_hyp[cur_biomarker, ] <- c(1.0, 7.0, 1.0, -4.0, -1.0)
    prec_hyp[cur_biomarker, , ] <- diag(c(1.0, 0.00001, 1.0, 0.001, 1.0))
    omega[cur_biomarker, , ] <- diag(c(1.0, 50.0, 1.0, 10.0, 1.0))
    wishdf[cur_biomarker] <- 20
    prec_logy_hyp[cur_biomarker, ] <- c(4.0, 1.0)
  }

  longdata <- list(
    "smpl.t" = sample_times, "logy" = logy,
    "ntest" = n_biomarkers, "nsmpl" = nsmpl, "nsubj" = nsubj + 1, "ndim" = ndim,
    "mu.hyp" = mu_hyp, "prec.hyp" = prec_hyp,
    "omega" = omega, "wishdf" = wishdf,
    "prec.logy.hyp" = prec_logy_hyp
  )

  return(longdata)
}
