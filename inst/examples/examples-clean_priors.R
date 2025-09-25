# Example: remove unused fields
priors <- list(
  omega = 1,
  wishdf = 10,
  mu.hyp = matrix(0, 1, 1),
  prec.par = 5
)

cleaned <- clean_priors(priors)
print(names(cleaned))
