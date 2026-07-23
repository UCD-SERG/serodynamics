#' @title Simulate Correlated Curve Parameters for Two Biomarkers
#' @author Kwan Ho Lee
#' @description
#'  `make_corr_curve_params()` draws `n_iter` joint sets of two-phase antibody
#'  curve parameters for a pair of antigen isotypes, with a cross-biomarker
#'  correlation specified separately for each of the five curve parameters.
#'  The result is a [serocalculator::curve_params] object that can be passed
#'  directly to [sim_case_data()], giving simulated data with a known
#'  cross-biomarker correlation to recover.
#'
#'  Parameters are drawn on the log scale the model works in, ordered
#'  `log_y0`, `log_y1y0`, `log_t1`, `log_k`, `log_shape1`. The natural-scale
#'  `alpha` in the output is recovered at the end from
#'  \deqn{\log \alpha = \log k - (r - 1) \log y_1,}
#'  which is the identity the two-phase model uses internally. Because the
#'  draws are made on the `log_k` scale, the correlation passed in `rho` is the
#'  correlation between the two biomarkers' model parameters, so the simulation
#'  truth and the estimand are the same quantity.
#'
#'  The joint \eqn{10 \times 10} covariance is built from a lower-triangular
#'  Cholesky factor
#'  \deqn{L = \begin{pmatrix} L_G & 0 \\ B & L_{A \cdot G} \end{pmatrix},
#'    \quad B = \mathrm{diag}(c) L_G^{-\top},
#'    \quad L_{A \cdot G} = \mathrm{chol}(\Sigma_A - B B^\top),}
#'  with \eqn{c_j = \rho_j \sigma_{G,j} \sigma_{A,j}}. The cross-biomarker
#'  block is then exactly \eqn{\mathrm{diag}(c)} and both within-biomarker
#'  blocks keep the values supplied, for any admissible `rho`. Setting
#'  `rho = rep(0, 5)` gives two independent biomarkers.
#'
#'  The within-biomarker blocks are full matrices, so not every vector in
#'  \eqn{[-1, 1]^5} is attainable -- \eqn{\Sigma_A - B B^\top} has to stay
#'  positive definite. `make_corr_curve_params()` checks this and stops if the
#'  requested `rho` cannot exist. Use [rho_admissible()] to test a vector
#'  before committing compute to it.
#'
#' @param n_iter [integer] number of joint parameter draws to generate.
#' @param mu_G,mu_A length-5 [numeric] population means on the log scale, in the
#'   order `log_y0`, `log_y1y0`, `log_t1`, `log_k`, `log_shape1`.
#' @param sigma_G,sigma_A \eqn{5 \times 5} within-biomarker covariance
#'   [matrix]es on the log scale.
#' @param sd_G,sd_A optional length-5 [numeric] standard deviations, used in
#'   place of `sigma_G`/`sigma_A` when the within-biomarker parameters should be
#'   mutually independent. Supplying these is equivalent to passing
#'   `diag(sd^2)`.
#' @param rho length-5 [numeric] cross-biomarker correlation, one entry per
#'   curve parameter. `rep(0, 5)` gives independent biomarkers.
#' @param targets optional [list] of population targets, or a file path to an
#'   `.rds` holding one, with elements `mu_G`, `mu_A`, `sigma_G` and `sigma_A`
#'   (`Sigma_G`/`Sigma_A` are also accepted). Any of `mu_G`, `mu_A`, `sigma_G`,
#'   `sigma_A` not supplied directly is taken from here, which makes it easy to
#'   drive a simulation from a previously fitted model.
#' @param antigen_isos length-2 [character] antigen isotype labels. The first
#'   pairs with the `_G` arguments, the second with the `_A` arguments.
#' @param biomarker_var [character] name of the antigen isotype column in the
#'   returned object.
#' @param check_admissible [logical] whether to stop when `rho` implies a
#'   non-positive-definite joint covariance. Leave this `TRUE` unless you are
#'   deliberately exploring the boundary.
#'
#' @returns A [serocalculator::curve_params] object with columns `iter`,
#'   `biomarker_var`, `y0`, `y1`, `t1`, `alpha` and `r`. The exact simulation
#'   truth is attached as the `"truth"` attribute, a [list] containing
#'   `mu_flat`, `sigma_full`, `sd_G`, `sd_A`, `c`, `rho`, `l_full` and
#'   `cross_corr`.
#'
#' @export
#'
#' @examples
#' set.seed(1)
#'
#' # independent within-biomarker parameters, moderate cross-correlation
#' cp <- make_corr_curve_params(
#'   n_iter = 500,
#'   mu_G = c(-0.2, 5.2, 1.9, -4.1, -0.4),
#'   mu_A = c(0.1, 4.3, 2.0, -2.7, 0.3),
#'   sd_G = c(0.34, 1.14, 0.64, 0.84, 0.27),
#'   sd_A = c(0.77, 1.35, 0.98, 1.50, 0.30),
#'   rho = c(-0.8, 0.6, 0.9, 0.8, 0.4)
#' )
#' head(cp)
#'
#' # the injected correlation is the truth, exactly
#' attr(cp, "truth")$cross_corr
make_corr_curve_params <- function(
    n_iter = 4000,
    mu_G = NULL,
    mu_A = NULL,
    sigma_G = NULL,
    sigma_A = NULL,
    sd_G = NULL,
    sd_A = NULL,
    rho = rep(0, 5),
    targets = NULL,
    antigen_isos = c("HlyE_IgG", "HlyE_IgA"),
    biomarker_var = "antigen_iso",
    check_admissible = TRUE) {

  spec <- resolve_curve_targets(
    mu_G = mu_G, mu_A = mu_A,
    sigma_G = sigma_G, sigma_A = sigma_A,
    sd_G = sd_G, sd_A = sd_A,
    targets = targets
  )

  validate_curve_spec(spec, rho = rho, n_iter = n_iter,
                      antigen_isos = antigen_isos)

  chol_parts <- joint_cholesky(
    sigma_G = spec$sigma_G,
    sigma_A = spec$sigma_A,
    rho = rho,
    check_admissible = check_admissible
  )

  n_par <- length(rho)
  mu_flat <- c(spec$mu_G, spec$mu_A)
  z_mat <- matrix(stats::rnorm(2 * n_par * n_iter), 2 * n_par, n_iter)
  par_mat <- t(mu_flat + chol_parts$l_full %*% z_mat)

  draws_G <- log_params_to_curve(par_mat[, seq_len(n_par), drop = FALSE])
  draws_A <- log_params_to_curve(
    par_mat[, n_par + seq_len(n_par), drop = FALSE]
  )
  draws_G$iter <- seq_len(n_iter)
  draws_A$iter <- seq_len(n_iter)
  draws_G[[biomarker_var]] <- antigen_isos[1]
  draws_A[[biomarker_var]] <- antigen_isos[2]

  out_df <- rbind(draws_G, draws_A)[
    , c("iter", biomarker_var, "y0", "y1", "t1", "alpha", "r")
  ]

  out <- as_sero_curve_params(out_df, biomarker_var, antigen_isos)
  attr(out, "sero_model") <- "corr_two_biomarker"
  attr(out, "truth") <- list(
    param_names = c("log_y0", "log_y1y0", "log_t1", "log_k", "log_shape1"),
    mu_G = spec$mu_G,
    mu_A = spec$mu_A,
    mu_flat = mu_flat,
    sigma_G = spec$sigma_G,
    sigma_A = spec$sigma_A,
    sigma_full = chol_parts$l_full %*% t(chol_parts$l_full),
    sd_G = chol_parts$sd_G,
    sd_A = chol_parts$sd_A,
    c = chol_parts$c_vec,
    rho = rho,
    l_full = chol_parts$l_full,
    cross_corr = rho,
    min_eig_cond = chol_parts$min_eig,
    n_iter = n_iter
  )
  out
}


#' @title Check Whether a Cross-Biomarker Correlation Is Attainable
#' @author Kwan Ho Lee
#' @description
#'  Given two within-biomarker covariance matrices, `rho_admissible()` reports
#'  whether a proposed cross-biomarker correlation vector gives a
#'  positive-definite joint covariance. Use it to lay out a grid of simulation
#'  scenarios before running any of them.
#'
#' @inheritParams make_corr_curve_params
#'
#' @returns A [list] with `admissible` ([logical]) and `min_eig` ([numeric]),
#'   the smallest eigenvalue of \eqn{\Sigma_A - B B^\top}.
#'
#' @export
#'
#' @examples
#' sigma_G <- diag(c(0.34, 1.14, 0.64, 0.84, 0.27)^2)
#' sigma_A <- diag(c(0.77, 1.35, 0.98, 1.50, 0.30)^2)
#' rho_admissible(sigma_G, sigma_A, rho = rep(0.6, 5))
#' rho_admissible(sigma_G, sigma_A, rho = rep(0.99, 5))
rho_admissible <- function(sigma_G, sigma_A, rho) {
  parts <- joint_cholesky(sigma_G, sigma_A, rho, check_admissible = FALSE)
  list(admissible = parts$min_eig > 1e-10, min_eig = parts$min_eig)
}


# Fill in any population targets not supplied directly ------------------------
resolve_curve_targets <- function(mu_G, mu_A, sigma_G, sigma_A,
                                  sd_G, sd_A, targets) {
  if (!is.null(targets)) {
    if (is.character(targets)) {
      targets <- readRDS(targets)
    }
    mu_G <- coalesce_target(mu_G, targets, "mu_G")
    mu_A <- coalesce_target(mu_A, targets, "mu_A")
    sigma_G <- coalesce_target(sigma_G, targets, "sigma_G", "Sigma_G")
    sigma_A <- coalesce_target(sigma_A, targets, "sigma_A", "Sigma_A")
  }
  if (is.null(sigma_G)) {
    sigma_G <- sd_to_cov(sd_G)
  }
  if (is.null(sigma_A)) {
    sigma_A <- sd_to_cov(sd_A)
  }
  list(
    mu_G = as.numeric(mu_G),
    mu_A = as.numeric(mu_A),
    sigma_G = symmetrize(sigma_G),
    sigma_A = symmetrize(sigma_A)
  )
}


coalesce_target <- function(value, targets, ...) {
  if (!is.null(value)) {
    return(value)
  }
  for (nm in c(...)) {
    if (!is.null(targets[[nm]])) {
      return(targets[[nm]])
    }
  }
  NULL
}


sd_to_cov <- function(sd_vec) {
  if (is.null(sd_vec)) {
    return(NULL)
  }
  diag(as.numeric(sd_vec)^2, length(sd_vec))
}


validate_curve_spec <- function(spec, rho, n_iter, antigen_isos) {
  n_par <- length(rho)
  if (is.null(spec$sigma_G) || is.null(spec$sigma_A)) {
    cli::cli_abort(
      "Supply {.arg sigma_G}/{.arg sigma_A}, {.arg sd_G}/{.arg sd_A}, or
       {.arg targets}."
    )
  }
  if (length(spec$mu_G) != n_par || length(spec$mu_A) != n_par) {
    cli::cli_abort(
      "{.arg mu_G} and {.arg mu_A} must both have length {n_par}, to match
       {.arg rho}."
    )
  }
  if (!identical(dim(spec$sigma_G), c(n_par, n_par)) ||
        !identical(dim(spec$sigma_A), c(n_par, n_par))) {
    cli::cli_abort(
      "{.arg sigma_G} and {.arg sigma_A} must both be {n_par} x {n_par}."
    )
  }
  if (any(abs(rho) > 1)) {
    cli::cli_abort("{.arg rho} must lie in [-1, 1].")
  }
  if (length(antigen_isos) != 2) {
    cli::cli_abort("{.arg antigen_isos} must have length 2.")
  }
  if (n_iter < 1) {
    cli::cli_abort("{.arg n_iter} must be at least 1.")
  }
  invisible(TRUE)
}


# Joint Cholesky factor with an exactly diagonal cross block ------------------
joint_cholesky <- function(sigma_G, sigma_A, rho, check_admissible = TRUE) {
  sigma_G <- symmetrize(sigma_G)
  sigma_A <- symmetrize(sigma_A)
  n_par <- length(rho)
  sd_G <- sqrt(diag(sigma_G))
  sd_A <- sqrt(diag(sigma_A))

  c_vec <- rho * sd_G * sd_A
  chol_G <- t(chol(sigma_G))
  b_mat <- diag(c_vec, nrow = n_par) %*% t(solve(chol_G))
  sigma_cond <- symmetrize(sigma_A - b_mat %*% t(b_mat))
  min_eig <- min(
    eigen(sigma_cond, symmetric = TRUE, only.values = TRUE)$values
  )

  if (check_admissible && min_eig <= 1e-10) {
    cli::cli_abort(c(
      "{.arg rho} is not attainable with these within-biomarker covariances.",
      "x" = "Smallest eigenvalue of {.code sigma_A - B B^T} is
             {signif(min_eig, 3)}; it must be positive.",
      "i" = "Shrink {.arg rho} or widen the within-biomarker covariances."
    ))
  }

  # When the conditional block is not positive definite there is no Cholesky to
  # take. Callers that opted out of the check (rho_admissible()) only need
  # `min_eig`, so return early rather than erroring inside chol().
  if (min_eig <= 1e-10) {
    return(list(
      l_full = NULL, sd_G = sd_G, sd_A = sd_A,
      c_vec = c_vec, min_eig = min_eig
    ))
  }

  chol_cond <- t(chol(sigma_cond))
  n_tot <- 2L * n_par
  l_full <- matrix(0, n_tot, n_tot)
  l_full[seq_len(n_par), seq_len(n_par)] <- chol_G
  l_full[n_par + seq_len(n_par), seq_len(n_par)] <- b_mat
  l_full[n_par + seq_len(n_par), n_par + seq_len(n_par)] <- chol_cond

  list(
    l_full = l_full, sd_G = sd_G, sd_A = sd_A,
    c_vec = c_vec, min_eig = min_eig
  )
}


# log-scale draws -> natural-scale curve parameters ---------------------------
log_params_to_curve <- function(log_par) {
  y0 <- exp(log_par[, 1])
  y1 <- y0 + exp(log_par[, 2])
  shape_less_one <- exp(log_par[, 5])
  log_alpha <- log_par[, 4] - shape_less_one * log(y1)
  data.frame(
    y0 = y0,
    y1 = y1,
    t1 = exp(log_par[, 3]),
    alpha = exp(log_alpha),
    r = 1 + shape_less_one
  )
}


symmetrize <- function(mat) {
  if (is.null(mat)) {
    return(NULL)
  }
  mat <- as.matrix(mat)
  (mat + t(mat)) / 2
}


# Wrap a plain data frame as a serocalculator curve_params object -------------
as_sero_curve_params <- function(out_df, biomarker_var, antigen_isos) {
  for (nm in c("as_sr_params", "as_curve_params")) {
    out <- try_sero_constructor(nm, out_df, biomarker_var, antigen_isos)
    if (!is.null(out)) {
      return(out)
    }
  }
  class(out_df) <- c("curve_params", class(out_df))
  attr(out_df, "biomarker_var") <- biomarker_var
  out_df
}


try_sero_constructor <- function(nm, out_df, biomarker_var, antigen_isos) {
  tryCatch(
    {
      fun <- utils::getFromNamespace(nm, "serocalculator")
      args <- list(out_df)
      formal_names <- names(formals(fun))
      if ("biomarker_var" %in% formal_names) {
        args$biomarker_var <- biomarker_var
      }
      if ("antigen_isos" %in% formal_names) {
        args$antigen_isos <- antigen_isos
      }
      do.call(fun, args)
    },
    error = function(e) NULL
  )
}
