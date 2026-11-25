test_that("load_data uses the revised peak prior for all biomarkers", {
  biomarkers <- c("HlyE_IgA", "HlyE_IgG", "LPS_IgA", "LPS_IgG",
                  "MP_IgA", "MP_IgG", "Vi_IgG")
  visits <- paste0("_visit", seq_len(7))
  columns <- c(outer(biomarkers, visits, paste0))
  measurements <- as.list(stats::setNames(rep(2, length(columns)), columns))
  visit_columns <- paste0("TimeInDays", visits)
  visit_times <- as.list(stats::setNames(seq_len(7), visit_columns))
  data <- data.frame(index_id = 1, age = 20, measurements, visit_times)

  path <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(data, path, row.names = FALSE)

  datapath <- paste0(dirname(path), .Platform$file.sep)
  prepped <- load_data(datapath, basename(path))

  expect_equal(prepped$prec.hyp[, 2, 2], rep(0.0001, length(biomarkers)))
})
