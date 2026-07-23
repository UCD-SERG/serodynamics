#' Convert a fitted Chapter-2 model into correlated `curve_params`
#'
#' Draws `n_iter` synthetic cases from the **fitted** Chapter-2 population
#' distribution and returns them as a `curve_params` object suitable for
#' [sim_case_data] (with `model = "ch2"` / `"auto"`). Use this to simulate data
#' whose cross-biomarker correlation matches what the model actually estimated
#' on the real data (e.g. the realistic Chapter-2 recovery check on nepal_sees
#' or Shigella).
#'
#' The Chapter-2 model draws each subject's transformed parameters as
#' `par = mu_flat + L_full %*% z`, `z ~ N(0, I)`, where `mu_flat` (length
#' `2*n_params`) and `L_full` (`2*n_params` square) are transformed parameters
#' of `model_ch2.stan`. This function takes their posterior means (the estimated
#' population), draws `n_iter` fresh subjects, and converts the transformed
#' parameters back to natural `curve_params` columns. The decay slot of the
#' model is `log_k`; it is converted back to `log_alpha` via
#' `log_alpha = log_k - exp(log_shape1) * log(exp(log_y0) + exp(log_y1y0))`.
#'
#' @param fit a fitted `CmdStanMCMC` object from `model_ch2.stan`
#'   (e.g. `readRDS("fit_ch2.rds")`), **or** `NULL` if supplying `mu_flat`/
#'   `L_full` directly.
#' @param n_iter [integer] number of synthetic cases (joint draws) to generate.
#' @param mu_flat optional length-`2*n_params` numeric: population mean on the
#'   transformed scale (order: IgG `log_y0,log_y1y0,log_t1,log_k,log_shape1`
#'   then IgA the same). If `NULL`, taken from `fit` (posterior mean of
#'   `mu_flat`).
#' @param L_full optional `2*n_params` square numeric Cholesky factor. If
#'   `NULL`, taken from `fit` (posterior mean of `L_full`).
#' @param n_params [integer] curve parameters per antigen (default 5).
#' @param antigen_isos length-2 character isotype labels (element 1 = IgG block).
#' @param biomarker_var [character] antigen column name in the output.
#'
#' @returns a `curve_params` data frame (`iter, <biomarker_var>, y0, y1, t1,
#'   alpha, r`) with attribute `"sero_model" = "ch2"`.
#' @export
#'
#' @examples
#' # fit <- readRDS("fit_ch2.rds")
#' # cp  <- ch2_fit_to_curve_params(fit, n_iter = 4000)
#' # cp |> sim_case_data(n = 300, spacing = "log", max_n_obs = 15, model = "ch2")
ch2_fit_to_curve_params <- function(fit = NULL,
                                    n_iter = 4000,
                                    mu_flat = NULL,
                                    L_full = NULL,
                                    n_params = 5L,
                                    antigen_isos = c("HlyE_IgG", "HlyE_IgA"),
                                    biomarker_var = "antigen_iso") {
  Q <- 2L * n_params

  # ---- pull mu_flat and L_full posterior means from the fit if not supplied ----
  if (is.null(mu_flat) || is.null(L_full)) {
    if (is.null(fit)) cli::cli_abort("Supply either {.arg fit} or both {.arg mu_flat} and {.arg L_full}.")
    s <- fit$summary(c("mu_flat", "L_full"))
    getv <- function(nm, len) {
      out <- numeric(len)
      for (i in seq_len(len)) out[i] <- s$mean[s$variable == sprintf("%s[%d]", nm, i)]
      out
    }
    getm <- function(nm, nr, nc) {
      M <- matrix(NA_real_, nr, nc)
      for (i in seq_len(nr)) for (j in seq_len(nc))
        M[i, j] <- s$mean[s$variable == sprintf("%s[%d,%d]", nm, i, j)]
      M
    }
    if (is.null(mu_flat)) mu_flat <- getv("mu_flat", Q)
    if (is.null(L_full))  L_full  <- getm("L_full", Q, Q)
    if (anyNA(mu_flat) || anyNA(L_full))
      cli::cli_abort("Could not read {.var mu_flat}/{.var L_full} from the fit; supply them directly.")
  }
  stopifnot(length(mu_flat) == Q, all(dim(L_full) == c(Q, Q)))

  # ---- draw n_iter fresh subjects: par = mu_flat + L_full %*% z ----
  Z <- matrix(rnorm(Q * n_iter), Q, n_iter)
  par <- matrix(mu_flat, Q, n_iter) + L_full %*% Z          # Q x n_iter (transformed scale)
  par <- t(par)                                             # n_iter x Q

  # ---- split into the two antigen blocks and convert to natural curve_params ----
  block_to_natural <- function(B) {
    log_y0 <- B[, 1]; log_y1y0 <- B[, 2]; log_t1 <- B[, 3]
    log_k  <- B[, 4]; log_shape1 <- B[, 5]
    log_y1 <- log(exp(log_y0) + exp(log_y1y0))
    log_alpha <- log_k - exp(log_shape1) * log_y1           # invert log_alpha -> log_k
    data.frame(
      y0    = exp(log_y0),
      y1    = exp(log_y0) + exp(log_y1y0),
      t1    = exp(log_t1),
      alpha = exp(log_alpha),
      r     = 1 + exp(log_shape1)
    )
  }
  gg <- block_to_natural(par[, 1:n_params, drop = FALSE])
  aa <- block_to_natural(par[, (n_params + 1):Q, drop = FALSE])
  gg$iter <- seq_len(n_iter); gg[[biomarker_var]] <- antigen_isos[1]
  aa$iter <- seq_len(n_iter); aa[[biomarker_var]] <- antigen_isos[2]

  out <- rbind(gg, aa)[, c("iter", biomarker_var, "y0", "y1", "t1", "alpha", "r")]
  class(out) <- c("curve_params", class(out))
  attr(out, "sero_model") <- "ch2"
  attr(out, "biomarker_var") <- biomarker_var
  out
}
