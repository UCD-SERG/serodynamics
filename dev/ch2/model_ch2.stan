// =====================================================================
// model_ch2.stan  --  Chapter 2 (Chapter1+alpha) cross-biomarker model.
// Extends the branch's model.stan DATA LAYOUT (prep_data_stan: padded 3D arrays) and
// PRIORS (prep_priors_stan: per-antigen inverse-Wishart, moment-matched to LKJ+lognormal).
// Couples the two antigens through a JOINT 10-vector per subject with block covariance
//   Sigma = [[Sig_G, C],[C^T, Sig_A]],  C = diag(c_1..c_5)  (same-parameter cross-cov).
// PD-safe (any c; C exactly diagonal; c=0 => Chapter 1):
//   L_full = [[L_G, 0],[B, L_Acond]],  B = diag(c) * inv(L_G)^T
// Decay sampled in the identified log_k basis (log_alpha reconstructed) for HMC stability.
//   estimate_c = 0  =>  c fixed at 0  =>  exactly Chapter 1 (strict nesting).
// REQUIRES n_antigen_isos = 2 (order: 1 = IgG, 2 = IgA).
// =====================================================================
functions {
  // p = (log_y0, log_y1y0, log_t1, log_k, log_shape1)  -- decay slot is log_k
  real two_phase_logk(real t, vector p) {
    real log_y0 = p[1];
    real y0     = exp(log_y0);
    real y1     = y0 + exp(p[2]);
    real log_y1 = log(y1);
    real t1     = exp(p[3]);
    real a      = exp(p[5]);                 // a = r - 1 > 0
    real log_alpha = p[4] - a * log_y1;      // reconstruct log_alpha from log_k (unit Jacobian)
    real beta   = (log_y1 - log_y0) / t1;
    real out;
    if (t <= t1) {
      out = log_y0 + beta * t;               // active phase
    } else {
      real dt = t - t1;
      real log_inner = p[5] + log_alpha + log(dt) + a * log_y1;   // log(a) = p[5]
      real inner = exp(fmin(fmax(log_inner, -60.0), 60.0));
      out = log_y1 - log1p(inner) / a;       // recovery phase
    }
    return fmin(fmax(out, -30.0), 30.0);
  }
}
data {
  int<lower=1> nsubj;
  int<lower=2, upper=2> n_antigen_isos;                     // MUST be 2 (IgG, IgA)
  int<lower=1> n_params;                                    // = 5
  array[nsubj] int<lower=0> nsmpl;
  int<lower=1> max_nsmpl;
  array[nsubj, max_nsmpl] real smpl_t;
  array[nsubj, max_nsmpl, n_antigen_isos] real logy;
  // ---- priors from prep_priors_stan_ch2 (per antigen; decay slot of mu_hyp is log_k) ----
  array[n_antigen_isos] vector[n_params] mu_hyp;
  array[n_antigen_isos] matrix[n_params, n_params] prec_hyp;
  array[n_antigen_isos] matrix[n_params, n_params] omega;
  array[n_antigen_isos] real<lower=n_params> wishdf;
  array[n_antigen_isos, 2] real<lower=0> prec_logy_hyp;
  // ---- Chapter 2 additions ----
  real<lower=0> c_prior_sd;                                 // prior sd for cross-covariances
  int<lower=0, upper=1> estimate_c;                         // 1 = Ch2 (c free); 0 = Ch1 (c=0)
}
transformed data {
  int Q = 2 * n_params;                                     // = 10
  int Ntot = 0;
  for (s in 1:nsubj) Ntot += nsmpl[s];
  Ntot = Ntot * n_antigen_isos;                             // total scalar measurements (for log_lik)
  // moment-match inverse-Wishart -> LKJ + lognormal, per antigen (same as branch model.stan)
  array[n_antigen_isos] vector[n_params] sigma_meanlog;
  array[n_antigen_isos] vector<lower=0>[n_params] sigma_sdlog;
  array[n_antigen_isos] real<lower=0> eta;
  for (k in 1:n_antigen_isos) {
    real shp = (wishdf[k] - n_params + 1) / 2.0;
    vector[n_params] om_diag = diagonal(omega[k]);
    for (j in 1:n_params) sigma_meanlog[k][j] = 0.5 * (log(om_diag[j] / 2.0) - digamma(shp));
    sigma_sdlog[k] = rep_vector(0.5 * sqrt(trigamma(shp)), n_params);
    eta[k] = fmax((wishdf[k] - 2.0 * n_params + 3.0) / 2.0, 0.1);
  }
}
parameters {
  array[n_antigen_isos] vector[n_params] mu_par;            // [1]=IgG [2]=IgA hyper means
  vector<lower=0>[n_params] sd_G;   cholesky_factor_corr[n_params] Lcorr_G;   // IgG within-block
  vector<lower=0>[n_params] sd_A;   cholesky_factor_corr[n_params] Lcorr_A;   // IgA conditional block
  vector[n_params] c_raw;                                   // cross-biomarker same-parameter covariances
  matrix[nsubj, Q] z;                                       // non-centered subject innovations
  vector<lower=0>[n_antigen_isos] prec_logy;               // measurement precision per antigen
}
transformed parameters {
  vector[n_params] c;
  if (estimate_c == 1) c = c_raw; else c = rep_vector(0.0, n_params);

  matrix[n_params, n_params] L_G  = diag_pre_multiply(sd_G, Lcorr_G);
  matrix[n_params, n_params] L_Ac = diag_pre_multiply(sd_A, Lcorr_A);
  matrix[n_params, n_params] B    = diag_pre_multiply(c, inverse(L_G)');   // diag(c) * inv(L_G)^T

  matrix[Q, Q] L_full = rep_matrix(0.0, Q, Q);
  L_full[1:n_params, 1:n_params]     = L_G;
  L_full[(n_params+1):Q, 1:n_params] = B;
  L_full[(n_params+1):Q, (n_params+1):Q] = L_Ac;

  vector[Q] mu_flat = append_row(mu_par[1], mu_par[2]);
  matrix[nsubj, Q] par = rep_matrix(mu_flat', nsubj) + z * L_full';         // par[s] = mu + L_full * z[s]
}
model {
  // priors (match branch: dmnorm precision on mu; IW->LKJ+lognormal on covariance; gamma on prec_logy)
  for (k in 1:n_antigen_isos) {
    mu_par[k]   ~ multi_normal_prec(mu_hyp[k], prec_hyp[k]);
    prec_logy[k] ~ gamma(prec_logy_hyp[k, 1], prec_logy_hyp[k, 2]);
  }
  sd_G ~ lognormal(sigma_meanlog[1], sigma_sdlog[1]);  Lcorr_G ~ lkj_corr_cholesky(eta[1]);
  sd_A ~ lognormal(sigma_meanlog[2], sigma_sdlog[2]);  Lcorr_A ~ lkj_corr_cholesky(eta[2]);
  c_raw ~ normal(0, c_prior_sd);
  to_vector(z) ~ std_normal();
  // likelihood (loop only up to nsmpl[subj]; padded entries ignored)
  for (s in 1:nsubj) {
    for (o in 1:nsmpl[s]) {
      for (k in 1:n_antigen_isos) {
        vector[n_params] p = par[s, ((k-1)*n_params + 1):(k*n_params)]';
        logy[s, o, k] ~ normal(two_phase_logk(smpl_t[s, o], p), inv_sqrt(prec_logy[k]));
      }
    }
  }
}
generated quantities {
  vector[Ntot] log_lik;
  vector[n_params] cross_corr;
  vector[n_params] cross_cov;
  {
    matrix[Q, Q] Sig = L_full * L_full';
    for (j in 1:n_params) {
      cross_cov[j]  = Sig[j, n_params + j];
      cross_corr[j] = Sig[j, n_params + j] / sqrt(Sig[j, j] * Sig[n_params + j, n_params + j]);
    }
    int pos = 1;
    for (s in 1:nsubj) {
      for (o in 1:nsmpl[s]) {
        for (k in 1:n_antigen_isos) {
          vector[n_params] p = par[s, ((k-1)*n_params + 1):(k*n_params)]';
          log_lik[pos] = normal_lpdf(logy[s, o, k] | two_phase_logk(smpl_t[s, o], p), inv_sqrt(prec_logy[k]));
          pos += 1;
        }
      }
    }
  }
}
