#' @title Write the Chapter 2 Kronecker JAGS model
#' @author Kwan Ho Lee
#' @description
#'  `write_model_ch2_kron()` emits a JAGS model file that places a
#'  Kronecker precision \eqn{T = T_B \otimes T_P} over stacked
#'  per-biomarker parameters (5 per biomarker).
#'
#'  Expected data in the JAGS environment includes:
#'  \itemize{
#'    \item scalar: `n_blocks`, `nsubj`, `n_params` (should be 5)
#'    \item hypermeans: `mu.hyp[b, ]`, hyper-precisions: `prec.hyp[b, , ]`
#'    \item Wishart pieces: `OmegaP[5,5]`, `nuP`, `OmegaB[n_blocks,n_blocks]`, 
#'    `nuB`
#'    \item measurement: `smpl.t`, `nsmpl`, `prec.logy.hyp`
#'  }
#'
#' @param path File path to write (default `"model_ch2_kron.jags"`).
#'
#' @return Invisibly returns `path`.
#'
#' @export
#' @example inst/examples/examples-write_model_ch2_kron.R
write_model_ch2_kron <- function(path = "model_ch2_kron.jags") {
  cat("
model {

  # Hyperpriors for population means (same shape as independence model)
  for (b in 1:n_blocks) {
    mu.par[b, 1:n_params] ~ dmnorm(mu.hyp[b, ], prec.hyp[b, , ])
  }

  # Wishart priors for Kronecker precision
  # within-biomarker (params)
  TauP[1:5,1:5] ~ dwish(OmegaP[1:5,1:5], nuP)      
  # across biomarkers
  TauB[1:n_blocks,1:n_blocks] ~ dwish(OmegaB[1:n_blocks,1:n_blocks], nuB) 

  # Tau = TauB ⊗ TauP
  for (b1 in 1:n_blocks) {
    for (b2 in 1:n_blocks) {
      for (p1 in 1:5) {
        for (p2 in 1:5) {
          Tau[(b1-1)*5 + p1, (b2-1)*5 + p2] <- TauB[b1,b2] * TauP[p1,p2]
        }
      }
    }
  }

  # Vectorized mean across biomarkers
  for (b in 1:n_blocks) {
    for (p in 1:5) {
      mu_vec[(b-1)*5 + p] <- mu.par[b,p]
    }
  }

  # Subject-level prior over stacked parameters
  for (subj in 1:nsubj) {
    par_vec[subj, 1:(5*B)] ~ dmnorm(mu_vec[1:(5*n_blocks)], Tau[ , ])

    # Unstack back to par[subj, b, p]
    for (b in 1:n_blocks) {
      for (p in 1:5) {
        par[subj, b, p] <- par_vec[subj, (b-1)*5 + p]
      }
    }

    # Transforms to natural scale
    for (b in 1:n_blocks) {
      y0[subj,b]    <- exp(par[subj,b,1])
      y1[subj,b]    <- y0[subj,b] + exp(par[subj,b,2])  # log(y1 - y0)
      t1[subj,b]    <- exp(par[subj,b,3])
      alpha[subj,b] <- exp(par[subj,b,4])
      shape[subj,b] <- exp(par[subj,b,5]) + 1
    }

    # Likelihood (unchanged)
    for (obs in 1:nsmpl[subj]) {
      for (b in 1:n_blocks) {
        beta_tmp[subj,b] <- log(y1[subj,b] / y0[subj,b]) / t1[subj,b]
        mu.logy[subj,obs,b] <- ifelse(
          step(t1[subj,b] - smpl.t[subj,obs]),
          log(y0[subj,b]) + beta_tmp[subj,b] * smpl.t[subj,obs],
          (1/(1-shape[subj,b])) * log(
            y1[subj,b]^(1-shape[subj,b]) -
            (1-shape[subj,b]) * alpha[subj,b] * (smpl.t[subj,obs] - t1[subj,b])
          )
        )
        logy[subj,obs,b] ~ dnorm(mu.logy[subj,obs,b], prec.logy[b])
      }
    }
  }

  # Measurement precisions
  for (b in 1:n_blocks) {
    prec.logy[b] ~ dgamma(prec.logy.hyp[b,1], prec.logy.hyp[b,2])
  }
}
", file = path)
  invisible(path)
}
