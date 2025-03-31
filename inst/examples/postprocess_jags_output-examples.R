set.seed(1)
raw_data <-
  serocalculator::typhoid_curves_nostrat_100 |>
  dplyr::filter(
    antigen_iso |> stringr::str_starts(pattern = "HlyE")
  ) |>
  sim_case_data(
    n = 5,
    antigen_isos = c("HlyE_IgA", "HlyE_IgG")
  )
prepped_data <- prep_data(raw_data)

jags_post <- run_mod(data = raw_data, nchain = 2, nadapt = 1000, nburn = 100, 
                     nmc = 100, niter = 200)

curve_params <- jags_post$jags.post$None$mcmc |> postprocess_jags_output(
  ids = attr(prepped_data, "ids"),
  antigen_isos = attr(prepped_data, "antigens")
)

print(curve_params)
