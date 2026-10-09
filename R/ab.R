ab <- function(t, y0, y1, t1, alpha, shape,
               decay_type = "power") {
  decay_type <- match.arg(decay_type, c("power", "exponential"))
  
  # Calculate antibody growth rate during active infection
  beta <- bt(y0, y1, t1)
  
  if (decay_type == "power") {
    # Power function decay (Teunis et al. 2016)
    yt <- ifelse(
      t <= t1,
      y0 * exp(beta * t),
      (y1^(1 - shape) - (1 - shape) * alpha * (t - t1))^(1 / (1 - shape))
    )
  } else {
    # Exponential decay
    yt <- ifelse(
      t <= t1,
      y0 * exp(beta * t),
      y1 * exp(-alpha * (t - t1))
    )
  }
  
  return(yt)
}
