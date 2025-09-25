# Example: use default serodynamics::ab
f <- make_ab_vec()

# Evaluate at three time points
f(t = c(0, 7, 14), y0 = 1, y1 = 6, t1 = 14, alpha = 0.02, shape = 2)
