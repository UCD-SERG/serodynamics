# results are consistent with simulated data

    list(names = c("id", "visit_num", "timeindays", "iter", "antigen_iso", 
    "y0", "y1", "t1", "alpha", "r", "value"), class = c("case_data", 
    "tbl_df", "tbl", "data.frame"), id_var = "id", biomarker_var = "antigen_iso", 
        timeindays = "timeindays", value_var = "value")

# results are consistent with SEES data

    list(names = c("Country", "id", "sample_id", "bldculres", "antigen_iso", 
    "studyvisit", "dayssincefeveronset", "result", "visit_num"), 
        class = c("case_data", "spec_tbl_df", "tbl_df", "tbl", "data.frame"
        ), id_var = "id", biomarker_var = "antigen_iso", timeindays = "dayssincefeveronset", 
        value_var = "result")

