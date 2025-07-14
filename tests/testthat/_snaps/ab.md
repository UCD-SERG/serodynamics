# results are consistent

    Code
      do.call(dplyr::mutate(dplyr::select(params, -c(antigen_iso, iter), shape = r),
      t = 10), what = ab)
    Output
      [1]  63.09329 157.74561

