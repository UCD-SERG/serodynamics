# results are consistent with our model

    Code
      head(unlist(stringr::str_split(as.character(jags_post$end.state), pattern = "\n")),
      1)
    Output
      [1] "\".RNG.state\" <- c(15587, 26869, 21639)"

