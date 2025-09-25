# Basic usage
t <- c(0, 7, 14, 30, 90)
two_phase_y(t, y0 = 1, y1 = 6, t1 = 14, alpha = 0.02, rho = 2)

# A quick plot (if graphics is available)
if (interactive()) {
  tt <- seq(0, 180, by = 1)
  yy <- two_phase_y(tt, y0 = 1, y1 = 8, t1 = 21, alpha = 0.015, rho = 1.8)
  plot(tt, yy, type = "l", xlab = "Days", ylab = "Antibody level",
       main = "Two-phase kinetics: rise then decay")
}
