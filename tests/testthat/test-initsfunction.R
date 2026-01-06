test_that("results are consistent", {
  initsfunction(c(4, 1, 3, 2)) |> expect_snapshot_value(style = "deparse")
})

test_that(
  desc = "runjags results are consistent", 
  code = {

    set.seed(1)
    data1 <- rbinom(n = 91, size = 1, prob = .6)
    jags_post0 <- run.jags(
      n.chains = 2,
      inits = initsfunction,
      method = "parallel",
      model = serodynamics_example("model.dobson.jags"),
      data = list(r = data1, N = length(data1)),
      monitor = "p",
      sample = 10
    ) |> suppressWarnings()
    
    jags_unpack <- ggmcmc::ggs(jags_post0[["mcmc"]])
    
    jags_unpack |> expect_snapshot_data("dobson")
    
  }
)
