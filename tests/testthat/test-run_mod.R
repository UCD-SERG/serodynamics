test_that(
  desc = "results are consistent", 
  code = 
    {
      skip_if(runjags::findjags() %in% c("", NULL))
      
      set.seed(1)
      library(dplyr)
      strat1 <- serocalculator::typhoid_curves_nostrat_100 |>
        sim_case_data(n = 100) |> 
        mutate(strat = "stratum 2")
      strat2 <- serocalculator::typhoid_curves_nostrat_100 |>
        sim_case_data(n = 100) |> 
        mutate(strat = "stratum 1")
      
      Dataset = bind_rows(strat1, strat2)
      
      withr::with_seed(
        1,
        code = {
          results <- run_mod(
            data = Dataset, #The data set input
            file_mod = fs::path_package("serodynamics", "extdata/model.jags.r"),
            nchain = 2, #Number of mcmc chains to run
            nadapt = 100, #Number of adaptations to run
            nburn = 100, #Number of unrecorded samples before sampling begins
            nmc = 100,
            niter = 100, #Number of iterations
            strat = "strat" #Variable to be stratified
          ) |> 
            suppressWarnings()
        }
      ) |> 
      expect_no_error()
    }
)
