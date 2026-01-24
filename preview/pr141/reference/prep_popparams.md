# Preparing population parameters

`prep_popparams` filters a
[data.frame](https://rdrr.io/r/base/data.frame.html) to only include
population parameters and renames the `Subject` variable as
`Population_Parameter`.

## Usage

``` r
prep_popparams(x)
```

## Arguments

- x:

  A [data.frame](https://rdrr.io/r/base/data.frame.html) with a
  `Subject` variable.

## Value

A filtered [data.frame](https://rdrr.io/r/base/data.frame.html) with the
`Subject` variable renamed to `Population_Parameter`.

## Author

Sam Schildhauer
