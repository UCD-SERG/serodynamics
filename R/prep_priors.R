prep_priors = function(n_antigens)
{
  
  n_params = 5  # Assuming 5 model parameters [ y0, y1, t1, alpha, shape]
  
  # Model parameters
  
  mu.hyp   <- array(NA, dim = c(n_antigens, n_params))
  prec.hyp <- array(NA, dim = c(n_antigens, n_params, n_params))
  omega    <- array(NA, dim = c(n_antigens, n_params, n_params))
  wishdf   <- rep(NA, n_antigens)
  prec.logy.hyp <- array(NA, dim = c(n_antigens, 2))
  
  # Fill parameter arrays
  # log(c(y0,  y1,    t1,  alpha, shape-1))
  # all biomarkers get the same prior hyperparameters
  for (k.test in 1:n_antigens) {
    mu.hyp[k.test,] <-        c(1.0, 7.0, 1.0, -4.0, -1.0)
    prec.hyp[k.test,,] <- diag(c(1.0, 0.00001, 1.0, 0.001, 1.0))
    omega[k.test,,] <-    diag(c(1.0, 50.0, 1.0, 10.0, 1.0))
    wishdf[k.test] <- 20
    prec.logy.hyp[k.test,] <- c(4.0, 1.0)
  }
  
  to_return = list(
    "n_params" = n_params,
    "mu.hyp" = mu.hyp, 
    "prec.hyp" = prec.hyp,
    "omega" = omega, 
    "wishdf" = wishdf,
    "prec.logy.hyp" = prec.logy.hyp
  )
  
  return(to_return)
}