# results are consistent with data frame showing parameter estimates

    Code
      results
    Output
      # A tibble: 20 x 11
      # Groups:   Iso_type, Parameter_sub [10]
         Iso_type Parameter_sub Stratification     Mean      SD  Median `2.5%` `25.0%`
         <chr>    <chr>         <chr>             <dbl>   <dbl>   <dbl>  <dbl>   <dbl>
       1 HlyE_IgA alpha         paratyphi         0.002 4   e-3   0.001  0       0.001
       2 HlyE_IgA alpha         typhi             0.004 4   e-3   0.002  0       0.001
       3 HlyE_IgA shape         paratyphi         1.71  3.14e-1   1.65   1.27    1.50 
       4 HlyE_IgA shape         typhi             1.68  3.5 e-1   1.60   1.28    1.43 
       5 HlyE_IgA t1            paratyphi         3.49  1.47e+0   3.18   1.49    2.36 
       6 HlyE_IgA t1            typhi             7.85  5.10e+0   6.87   2.05    4.57 
       7 HlyE_IgA y0            paratyphi         2.51  9.51e-1   2.35   1.04    1.83 
       8 HlyE_IgA y0            typhi             2.98  2.73e+0   2.44   0.694   1.75 
       9 HlyE_IgA y1            paratyphi      1111.    8.68e+3 154.     7.89   51.4  
      10 HlyE_IgA y1            typhi           996.    3.51e+3 205.     6.74   68.9  
      11 HlyE_IgG alpha         paratyphi         0.003 2   e-3   0.002  0       0.001
      12 HlyE_IgG alpha         typhi             0.002 2   e-3   0.001  0       0.001
      13 HlyE_IgG shape         paratyphi         1.31  1.24e-1   1.30   1.12    1.21 
      14 HlyE_IgG shape         typhi             1.47  4.06e-1   1.37   1.07    1.22 
      15 HlyE_IgG t1            paratyphi         4.69  1.88e+0   4.31   1.99    3.43 
      16 HlyE_IgG t1            typhi             7.89  6.30e+0   6.34   1.70    3.88 
      17 HlyE_IgG y0            paratyphi         2.02  8.72e-1   1.85   1.01    1.50 
      18 HlyE_IgG y0            typhi             2.05  1.68e+0   1.70   0.34    1.08 
      19 HlyE_IgG y1            paratyphi       436.    7.47e+2 191.    14.2    80.0  
      20 HlyE_IgG y1            typhi           616.    2.12e+3 236.    19.2   103.   
      # i 3 more variables: `50.0%` <dbl>, `75.0%` <dbl>, `97.5%` <dbl>

