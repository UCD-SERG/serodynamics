bt <- function(y0, y1, t1) log(y1 / y0) / t1

sero <- function(n, tvec, y0, y1, t1, alpha, shape) {
  tmp <- rep(NA, length(tvec))
  for (k in seq_along(tvec)) {
    tmp[k] <- ab(tvec[k], y0[n], y1[n], t1[n], alpha[n], shape[n])
  }
  return(tmp)
}

qsero <- function(t, q, y0, y1, t1, alpha, shape) {
  nmc <- length(y0)
  tmp <- rep(NA, nmc)
  for (k in 1:nmc) {
    tmp[k] <- ab(t, y0[k], y1[k], t1[k], alpha[k], shape[k])
  }
  if (length(q) == 1) if (q == "mean") {
    return(exp(mean(log(tmp))))
  }
  return(quantile(tmp, q))
}

serocourse <- function(tvec, q, y0, y1, t1, alpha, shape) {
  n_pts <- length(tvec)
  tmp <- rep(NA, n_pts)
  for (k in seq_along(tvec)) {
    tmp[k] <- qsero(tvec[k], q, y0, y1, t1, alpha, shape)
  }
  return(tmp)
}

wdens <- function(w, y1, alpha, shape) {
  rho <- 1 / (shape - 1)
  dens <- 1 / (w * gamma(rho)) * (w * rho / alpha)^rho *
    exp(-w * rho * y1^(-1 / rho) / alpha)
  return(dens)
}

wdistquan <- function(wvec, qvec, y1, alpha, shape) {
  densvec <- array(NA, dim = c(length(wvec), length(qvec)))
  for (k.w in seq_along(wvec)) {
    densvec[k.w, ] <- quantile(
      wdens(wvec[k.w], y1, alpha, shape),
      qvec,
      na.rm = TRUE
    )
  }
  return(densvec)
}

wlogdistquan <- function(logwvec, qvec, y1, alpha, shape) {
  densvec <- array(NA, dim = c(length(logwvec), length(qvec)))
  for (k.w in seq_along(logwvec)) {
    densvec[k.w, ] <- 10^logwvec[k.w] * log(10) *
      quantile(wdens(10^logwvec[k.w], y1, alpha, shape), qvec, na.rm = TRUE)
  }
  return(densvec)
}
