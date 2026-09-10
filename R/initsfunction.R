#' JAGS chain initialization function
#'
#' @param chain an [integer] specifying which chain to initialize
#'
#' @returns a [list] of RNG seeds and names
#' @export
#'
#' @examples initsfunction(1)
initsfunction <- function(chain) {
  stopifnot(chain %in% (1:4)) # max 4 chains allowed...
  rng_seed <- (1:4)[chain]
  rng_name <- c(
    "base::Wichmann-Hill", "base::Marsaglia-Multicarry",
    "base::Super-Duper", "base::Mersenne-Twister"
  )[chain]
  return(list(".RNG.seed" = rng_seed, ".RNG.name" = rng_name))
}

build_chain_inits <- function(longdata, chain, n_params) {
  stopifnot(n_params %in% c(4L, 5L))

  init_values <- initsfunction(chain)
  par_init <- array(
    0,
    dim = c(
      longdata$nsubj,
      longdata$n_antigen_isos,
      n_params
    )
  )

  # Keep deterministic starts in a numerically stable region.
  # JAGS may evaluate both branches of the piecewise mean expression when
  # checking initial values, so start with a very small decay rate and a shape
  # that is close to exponential decay.
  par_init[, , 4] <- -10

  if (n_params == 5L) {
    par_init[, , 5] <- -10
  }

  return(c(init_values, list(par = par_init)))
}
