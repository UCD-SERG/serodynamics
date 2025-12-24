# results are consistent with printed output for sr_model class

    Code
      nepal_sees_jags_output
    Output
      An sr_model with the following median values:
      
        Stratification Iso_type       alpha    shape      t1       y0       y1
      1          typhi HlyE_IgA 0.000869201 1.587970 6.41418 2.486935 317.1110
      2      paratyphi HlyE_IgA 0.001556295 1.561960 3.90369 2.852925 191.8805
      3          typhi HlyE_IgG 0.001337480 1.304980 5.88293 1.805900 297.7720
      4      paratyphi HlyE_IgG 0.001432405 1.386685 4.72698 2.330555 272.8455

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

