# Example: use default serodynamics::ab
f <- make_ab_vec()

# Evaluate at three time points
f(t = c(0, 7, 14), y0 = 1, y1 = 6, t1 = 14, alpha = 0.02, shape = 2)

# Example: override with custom toy function
toy_fun <- function(t, y0, y1, t1, alpha, shape) {
  y0 + (y1 - y0) * (1 - exp(-alpha * t))
}

f2 <- make_ab_vec(toy_fun)
f2(t = 0:5, y0 = 1, y1 = 10, t1 = 14, alpha = 0.1, shape = 2)
