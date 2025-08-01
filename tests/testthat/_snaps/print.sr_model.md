# results are consistent with printed output for sr_model class

    Code
      print(nepal_sees_jags_output)
    Output
      An sr_model with the following mean values:
      
    Condition
      Warning:
      Use of .data in tidyselect expressions was deprecated in tidyselect 1.2.0.
      i Please use `"Stratification"` instead of `.data$Stratification`
      Warning:
      Use of .data in tidyselect expressions was deprecated in tidyselect 1.2.0.
      i Please use `"Iso_type"` instead of `.data$Iso_type`
      Warning:
      Use of .data in tidyselect expressions was deprecated in tidyselect 1.2.0.
      i Please use `"Parameter"` instead of `.data$Parameter`
      Warning:
      Use of .data in tidyselect expressions was deprecated in tidyselect 1.2.0.
      i Please use `"Parameter"` instead of `.data$Parameter`
      Warning:
      Use of .data in tidyselect expressions was deprecated in tidyselect 1.2.0.
      i Please use `"mean_val"` instead of `.data$mean_val`
      Warning:
      Use of .data in tidyselect expressions was deprecated in tidyselect 1.2.0.
      i Please use `"Parameter"` instead of `.data$Parameter`
      Warning:
      Use of .data in tidyselect expressions was deprecated in tidyselect 1.2.0.
      i Please use `"mean_val"` instead of `.data$mean_val`
    Output
      # A tibble: 4 x 7
        Stratification Iso_type   alpha shape    t1    y0    y1
        <chr>          <chr>      <dbl> <dbl> <dbl> <dbl> <dbl>
      1 typhi          HlyE_IgA 0.00291  1.61  7.31  2.97 1032.
      2 paratyphi      HlyE_IgA 0.00229  1.66  3.85  2.55 1024.
      3 typhi          HlyE_IgG 0.00154  1.41  8.73  2.31  339.
      4 paratyphi      HlyE_IgG 0.00257  1.36  4.78  1.72  833.

