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
  .RNG.seed <- (1:4)[chain]
  .RNG.name <- c(
    "base::Wichmann-Hill", "base::Marsaglia-Multicarry",
    "base::Super-Duper", "base::Mersenne-Twister"
  )[chain]
  return(list(".RNG.seed" = .RNG.seed, ".RNG.name" = .RNG.name))
}