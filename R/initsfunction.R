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
