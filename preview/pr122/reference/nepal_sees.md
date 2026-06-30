# SEES Typhoid data

A subset of data from the SEES project highlighting Typhoid longitudinal
data from Nepal.

## Usage

``` r
nepal_sees
```

## Format

### `nepal_sees`

A [`base::data.frame()`](https://rdrr.io/r/base/data.frame.html) with
904 rows and 8 columns:

- Country:

  Country name

- person_id:

  ID identifying a study participant

- sample_id:

  ID identifying sample taken

- bldculres:

  Pathogen participant tested positive for; Typhoid or paratyphoid

- antigen_iso:

  The antigen/antibody combination included in the assay

- studyvisit:

  Categorical estimated time frame for when sample was taken; 28 days,
  3_months, 6_months, 12_months, baseline, or 18_months

- dayssincefeveronset:

  Continuous measurement showing how exact days since symptom onset

- result:

  Continuous variable describing ELISA result

## Source

reference study: <https://doi.org/10.1016/S2666-5247(22)00114-8>
