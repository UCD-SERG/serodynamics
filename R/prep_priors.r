

prep_priors <- function(max_antigens){
  
  # Model parameters
  ndim <- 5  # Assuming 5 model parameters [ y0, y1, t1, alpha, shape]
  mu.hyp   <- array(NA, dim = c(max_antigens, ndim))
  prec.hyp <- array(NA, dim = c(max_antigens, ndim, ndim))
  omega    <- array(NA, dim = c(max_antigens, ndim, ndim))
  wishdf   <- rep(NA, max_antigens)
  prec.logy.hyp <- array(NA, dim = c(max_antigens, 2))
  
  # Fill parameter arrays
  # log(c(y0,  y1,    t1,  alpha, shape-1))
  for (k.test in 1:max_antigens) {
    mu.hyp[k.test,] <-        c(1.0, 7.0, 1.0, -4.0, -1.0)
    prec.hyp[k.test,,] <- diag(c(1.0, 0.00001, 1.0, 0.001, 1.0))
    omega[k.test,,] <-    diag(c(1.0, 50.0, 1.0, 10.0, 1.0))
    wishdf[k.test] <- 20
    prec.logy.hyp[k.test,] <- c(4.0, 1.0)
  }
  
  
  
  # Return results as a list
  return(list(
    "ndim" = ndim,
    "mu.hyp" = mu.hyp, 
    "prec.hyp" = prec.hyp,
    "omega" = omega, 
    "wishdf" = wishdf,
    "prec.logy.hyp" = prec.logy.hyp
  ))  
  
  
  
}

