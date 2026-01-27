# load and format data

Load and format typhoid case data from a CSV file into a structured list
for use with JAGS Bayesian modeling. The function processes longitudinal
antibody measurements across multiple biomarkers and visits.

## Usage

``` r
load_data(
  datapath = "inst/extdata/",
  datafile = "TypoidCaseData_github_09.30.21.csv"
)
```

## Arguments

- datapath:

  path to data folder

- datafile:

  data file name

## Value

a [list](https://rdrr.io/r/base/list.html) with the following elements:

- `smpl.t` = time since symptom/fever onset for each participant, max 7
  visits

- `logy` = log antibody response at each time-point (max 7) for each of
  7 biomarkers for each participant

- `ntest` is max number of biomarkers

- `nsmpl` = max number of samples per participant

- `nsubj` = number of study participants

- `ndim` = number of parameters to model(y0, y1, t1, alpha, shape)

- `my.hyp`, `prec.hyp`, `omega` and `wishdf` are all parameters to
  describe the shape of priors for (y0, y1, t1, alpha, shape)
