# get_original_data requires original_data for new color stratification

    Code
      get_original_data(model, original_data = NULL, strat = "existing_strat",
        color_strat = TRUE, color_by_strat = "new_strat")
    Condition
      Error in `get_original_data()`:
      x Must include `original_data` when stratifying by `facet_by_strat` or `color_by_strat`.

