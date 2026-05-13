// Simple Bernoulli model (Dobson example)
// Translated from model.dobson.jags

data {
  int<lower=0> N;          // number of observations
  array[N] int<lower=0, upper=1> r;  // binary outcomes
}

parameters {
  real<lower=0, upper=1> p;  // probability parameter
}

model {
  // Prior: Beta(1, 1) = Uniform(0, 1)
  p ~ beta(1, 1);
  
  // Likelihood: Bernoulli trials
  r ~ bernoulli(p);
}
