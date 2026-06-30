// ============================================================================
// model_2a.stan  --  Chapter 2, Model 2a = "Chapter1+alpha"
// Author: Kwan Ho Lee
//
// The HONEST generalization of Chapter 1: keep Chapter 1's two FULL 5x5
// within-biomarker covariance blocks unchanged, and add ONLY the 5
// same-parameter cross-biomarker covariances. The between-subject covariance is
//
//     Sigma = [ Sigma_1   C      ]      C = diag(c_1, ..., c_5),
//             [ C'        Sigma_2 ]
//
// where Sigma_1, Sigma_2 are free 5x5 (exactly as Chapter 1) and the only
// cross-biomarker terms are the diagonal C: c_p couples parameter p across the
// two biomarkers (e.g. c_4 couples IgA decay with IgG decay). Setting C = 0
// recovers Chapter 1 EXACTLY, so Model 2a strictly NESTS Chapter 1 (35 vs 30
// covariance parameters). This nesting is the point: "Chapter 1 converges, so
// this should too" is a valid argument here, unlike for the (non-nested)
// Kronecker model.
//
// This is K = 2 (two biomarkers). Block 1 = antigen 1, block 2 = antigen 2, in
// the data's antigen order (alphabetical: IgA = antigen 1, IgG = antigen 2). The
// off-diagonal cross-parameter cross-biomarker terms (IgA parameter p vs IgG
// parameter q, p != q) are ZERO by construction -- that is the Chapter1+alpha
// structure, deliberately well below the 55-parameter saturated model.
//
// ---- How positive-definiteness is guaranteed (conditional / Schur form) -----
// A free Sigma_1, a free Sigma_2, and a free diagonal C need NOT form a PD joint
// matrix. Instead of constraining C, we build the joint via the conditional
// factorization, which is PD for ANY real c:
//
//     theta_1 ~ MVN(mu_1, Sigma_1)
//     theta_2 | theta_1 ~ MVN(mu_2 + B (theta_1 - mu_1), Psi),   B = C Sigma_1^-1
//
// This yields  Cov(theta_2, theta_1) = B Sigma_1 = C  (diagonal, as required),
// Cov(theta_1) = Sigma_1 (free, unchanged), and the marginal block-2 covariance
// Sigma_2 = B Sigma_1 B' + Psi. As Psi ranges over PD matrices, Sigma_2 ranges
// over exactly the block-2 covariances that keep the joint PD -- so the family
// is exactly Chapter1+alpha, with no rejection sampling. At C = 0, B = 0 and
// Sigma_2 = Psi: block-diagonal Chapter 1.
//
// Priors are matched to Chapter 1: Sigma_1 and Psi each get the per-antigen
// LKJ + lognormal factorization of model.stan (so at C = 0 the prior is exactly
// Chapter 1's). The new cross-couplings c_p get a weakly-informative prior
// centered at 0 (Chapter 1 at the prior mode).
//
// NOTE: starting model for Chapter 2; not yet fit on Mercury. Keep
// max_treedepth = 12 and the default init unless testing shows otherwise (see
// the Chapter 1 experience).
// ============================================================================

functions {
  // log y(t) for both phases -- identical to model.stan / model.jags.
  real log_two_phase(real t,
                     real log_y0, real log_y1, real y1,
                     real t1, real alpha, real shape) {
    if (t <= t1) {
      return log_y0 + (log_y1 - log_y0) / t1 * t;
    }
    real a = shape - 1;
    return log_y1 - log1p(a * alpha * (t - t1) * pow(y1, a)) / a;
  }
}

data {
  int<lower=2, upper=2> n_antigen_isos;                    // K = 2 (this model is pairwise)
  int<lower=1> nsubj;
  int<lower=1> n_params;                                    // = 5
  array[nsubj] int<lower=0> nsmpl;
  int<lower=1> max_nsmpl;
  array[nsubj, max_nsmpl] real smpl_t;
  array[nsubj, max_nsmpl, n_antigen_isos] real logy;

  // Priors (same per-antigen inputs as Chapter 1 prep_priors).
  array[n_antigen_isos] vector[n_params] mu_hyp;
  array[n_antigen_isos] matrix[n_params, n_params] prec_hyp;
  array[n_antigen_isos] matrix[n_params, n_params] omega;
  array[n_antigen_isos] real<lower=n_params> wishdf;
  array[n_antigen_isos, 2] real<lower=0> prec_logy_hyp;
}

transformed data {
  int n_total = n_antigen_isos * n_params;                 // = 10

  // Per-antigen scale + LKJ shape matched to each antigen's inverse-Wishart
  // (identical to Chapter 1 model.stan). Block 1 uses antigen 1's prior; the
  // conditional covariance Psi uses antigen 2's prior (so that at C = 0, where
  // Sigma_2 = Psi, block 2's prior is exactly Chapter 1's).
  array[n_antigen_isos] vector[n_params] sigma_meanlog;
  array[n_antigen_isos] vector<lower=0>[n_params] sigma_sdlog;
  array[n_antigen_isos] real<lower=0> eta;
  for (k in 1:n_antigen_isos) {
    real shp = (wishdf[k] - n_params + 1) / 2.0;
    vector[n_params] om_diag = diagonal(omega[k]);
    for (j in 1:n_params) {
      sigma_meanlog[k][j] = 0.5 * (log(om_diag[j] / 2.0) - digamma(shp));
    }
    sigma_sdlog[k] = rep_vector(0.5 * sqrt(trigamma(shp)), n_params);
    eta[k] = fmax((wishdf[k] - 2.0 * n_params + 3.0) / 2.0, 0.1);
  }

  // Weakly-informative prior scale for each cross-coupling c_p: the product of
  // the two biomarkers' prior-median marginal SDs (i.e. a covariance consistent
  // with ~unit cross-correlation). Tune the 1.0 multiplier to tighten/loosen.
  vector<lower=0>[n_params] c_scale;
  for (p in 1:n_params) {
    c_scale[p] = 1.0 * exp(sigma_meanlog[1][p]) * exp(sigma_meanlog[2][p]);
  }
}

parameters {
  array[n_antigen_isos] vector[n_params] mu_par;           // population means (per antigen)

  // Block 1 (free 5x5, = Chapter 1's first biomarker block).
  vector<lower=0>[n_params] sigma_1;
  cholesky_factor_corr[n_params] L_corr_1;

  // Conditional (Schur) covariance of block 2 given block 1 (free 5x5).
  vector<lower=0>[n_params] sigma_psi;
  cholesky_factor_corr[n_params] L_corr_psi;

  // The 5 same-parameter cross-biomarker covariances (the ONLY new parameters).
  vector[n_params] c_cross;

  array[nsubj] vector[n_params] z1;                        // non-centered, block 1
  array[nsubj] vector[n_params] z2;                        // non-centered, block 2 | block 1
  array[n_antigen_isos] real<lower=0> prec_logy;
}

transformed parameters {
  matrix[n_params, n_params] L_1     = diag_pre_multiply(sigma_1,   L_corr_1);
  matrix[n_params, n_params] L_psi   = diag_pre_multiply(sigma_psi, L_corr_psi);
  matrix[n_params, n_params] Sigma_1 = multiply_lower_tri_self_transpose(L_1);
  // B = C Sigma_1^-1  with C = diag(c_cross); mdivide_right_spd(M, A) = M A^-1.
  matrix[n_params, n_params] B = mdivide_right_spd(diag_matrix(c_cross), Sigma_1);

  array[nsubj, n_antigen_isos] vector[n_params] par;
  array[nsubj, n_antigen_isos] real<lower=0> y0;
  array[nsubj, n_antigen_isos] real<lower=0> y1;
  array[nsubj, n_antigen_isos] real<lower=0> t1;
  array[nsubj, n_antigen_isos] real<lower=0> alpha;
  array[nsubj, n_antigen_isos] real<lower=1> shape;

  for (subj in 1:nsubj) {
    // Conditional construction (PD for any c_cross):
    vector[n_params] theta1 = mu_par[1] + L_1 * z1[subj];
    vector[n_params] theta2 = mu_par[2] + B * (theta1 - mu_par[1]) + L_psi * z2[subj];
    par[subj, 1] = theta1;
    par[subj, 2] = theta2;

    for (k in 1:n_antigen_isos) {
      y0[subj, k]    = exp(par[subj, k][1]);
      y1[subj, k]    = y0[subj, k] + exp(par[subj, k][2]);
      t1[subj, k]    = exp(par[subj, k][3]);
      alpha[subj, k] = exp(par[subj, k][4]);
      shape[subj, k] = exp(par[subj, k][5]) + 1;
    }
  }
}

model {
  // ---- Hyperpriors (matched to Chapter 1) ------------------------------------
  for (k in 1:n_antigen_isos) {
    mu_par[k]    ~ multi_normal_prec(mu_hyp[k], prec_hyp[k]);
    prec_logy[k] ~ gamma(prec_logy_hyp[k, 1], prec_logy_hyp[k, 2]);
  }
  sigma_1     ~ lognormal(sigma_meanlog[1], sigma_sdlog[1]);   // block-1 scale (= Chapter 1)
  L_corr_1    ~ lkj_corr_cholesky(eta[1]);                     // block-1 correlation (= Chapter 1)
  sigma_psi   ~ lognormal(sigma_meanlog[2], sigma_sdlog[2]);   // block-2 scale via Psi (= Chapter 1 at C=0)
  L_corr_psi  ~ lkj_corr_cholesky(eta[2]);
  c_cross     ~ normal(0, c_scale);                           // NEW: cross-couplings, 0-centered

  // ---- Subject random effects (non-centered) ---------------------------------
  for (subj in 1:nsubj) {
    z1[subj] ~ std_normal();
    z2[subj] ~ std_normal();
  }

  // ---- Likelihood ------------------------------------------------------------
  for (subj in 1:nsubj) {
    if (nsmpl[subj] > 0) {
      for (obs in 1:nsmpl[subj]) {
        for (k in 1:n_antigen_isos) {
          real mu_logy = log_two_phase(
            smpl_t[subj, obs],
            log(y0[subj, k]), log(y1[subj, k]), y1[subj, k],
            t1[subj, k], alpha[subj, k], shape[subj, k]);
          logy[subj, obs, k] ~ normal(mu_logy, inv_sqrt(prec_logy[k]));
        }
      }
    }
  }
}

generated quantities {
  // Marginal block-2 covariance and the assembled joint covariance.
  matrix[n_params, n_params] Sigma_2 =
    quad_form_sym(Sigma_1, B') + multiply_lower_tri_self_transpose(L_psi);

  matrix[n_total, n_total] Sigma_joint = rep_matrix(0, n_total, n_total);
  Sigma_joint[1:n_params, 1:n_params] = Sigma_1;
  Sigma_joint[(n_params + 1):n_total, (n_params + 1):n_total] = Sigma_2;
  for (p in 1:n_params) {
    Sigma_joint[p, n_params + p] = c_cross[p];   // diagonal cross-block
    Sigma_joint[n_params + p, p] = c_cross[p];
  }

  // Same-parameter cross-biomarker correlations (the Chapter 2 estimand).
  // cross_cor[p] = corr(parameter p of antigen 1, parameter p of antigen 2).
  // Order (y0, log(y1-y0), t1, alpha, shape), so cross_cor[4] is the IgA-vs-IgG
  // DECAY correlation. The off-diagonal cross-parameter terms are 0 by design.
  vector[n_params] cross_cor;
  for (p in 1:n_params) {
    cross_cor[p] = c_cross[p] / sqrt(Sigma_1[p, p] * Sigma_2[p, p]);
  }
  vector[n_params] c_par = c_cross;              // raw cross-covariances

  // Pointwise (per-subject) log-likelihood for LOO / WAIC.
  vector[nsubj] log_lik;
  for (subj in 1:nsubj) {
    log_lik[subj] = 0;
    if (nsmpl[subj] > 0) {
      for (obs in 1:nsmpl[subj]) {
        for (k in 1:n_antigen_isos) {
          real mu_logy = log_two_phase(
            smpl_t[subj, obs],
            log(y0[subj, k]), log(y1[subj, k]), y1[subj, k],
            t1[subj, k], alpha[subj, k], shape[subj, k]);
          log_lik[subj] += normal_lpdf(logy[subj, obs, k] | mu_logy,
                                       inv_sqrt(prec_logy[k]));
        }
      }
    }
  }
}
