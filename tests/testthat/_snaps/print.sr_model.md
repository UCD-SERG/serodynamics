# results are consistent with printed output for sr_model class

    Code
      nepal_sees_jags_output
    Output
      An sr_model with the following median values:
      
        Stratification Iso_type       alpha    shape       t1       y0       y1
      1          typhi HlyE_IgA 0.001508265 1.673340 6.358405 2.340330 258.1235
      2      paratyphi HlyE_IgA 0.001556295 1.561960 3.903690 2.852925 191.8805
      3          typhi HlyE_IgG 0.001393980 1.385280 6.019110 1.788035 243.9110
      4      paratyphi HlyE_IgG 0.001432405 1.386685 4.726980 2.330555 272.8455

# results are consistent with printed output for sr_model class as tbl

    Code
      print(nepal_sees_jags_output, print_tbl = TRUE)
    Output
      # A tibble: 70,000 x 7
         Iteration Chain Parameter Iso_type Stratification Subject      value
             <int> <int> <chr>     <chr>    <chr>          <chr>        <dbl>
       1         1     1 alpha     HlyE_IgA typhi          sees_npl_1 0.00757
       2         2     1 alpha     HlyE_IgA typhi          sees_npl_1 0.00794
       3         3     1 alpha     HlyE_IgA typhi          sees_npl_1 0.00794
       4         4     1 alpha     HlyE_IgA typhi          sees_npl_1 0.0103 
       5         5     1 alpha     HlyE_IgA typhi          sees_npl_1 0.00925
       6         6     1 alpha     HlyE_IgA typhi          sees_npl_1 0.00925
       7         7     1 alpha     HlyE_IgA typhi          sees_npl_1 0.00950
       8         8     1 alpha     HlyE_IgA typhi          sees_npl_1 0.00950
       9         9     1 alpha     HlyE_IgA typhi          sees_npl_1 0.00852
      10        10     1 alpha     HlyE_IgA typhi          sees_npl_1 0.00852
      # i 69,990 more rows

# results consistent with printed output for sr_model as tbl no strat

    Code
      print(results)
    Output
      An sr_model with the following median values:
      
        Iso_type      alpha    shape       t1       y0       y1
      1 HlyE_IgA 0.01718040 1.368230 2.755075 2.646905 1184.585
      2 HlyE_IgG 0.01005685 1.293325 2.910905 2.641075  817.486

