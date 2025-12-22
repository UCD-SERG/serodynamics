# Basic usage with default RNG initializer
inits_kron(1)

# Using a custom base initializer
custom_inits <- function(chain) {
  list(.RNG.name = "base::Wichmann-Hill",
       .RNG.seed = 100 + chain,
       extra = "foo")
}
inits_kron(2, base_inits = custom_inits)
