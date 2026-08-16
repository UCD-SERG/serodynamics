# Snapshot testing for [data.frame](https://rdrr.io/r/base/data.frame.html)s

copied from <https://github.com/bcgov/ssdtools> with permission
(<https://github.com/bcgov/ssdtools/issues/379>)

## Usage

``` r
expect_snapshot_data(x, name, digits = 6, ...)
```

## Arguments

- x:

  a [data.frame](https://rdrr.io/r/base/data.frame.html) to snapshot

- name:

  [character](https://rdrr.io/r/base/character.html) snapshot name

- digits:

  [integer](https://rdrr.io/r/base/integer.html) passed to
  [`signif()`](https://rdrr.io/r/base/Round.html) for numeric variables

- ...:

  Arguments passed on to
  [`testthat::expect_snapshot_file`](https://testthat.r-lib.org/reference/expect_snapshot_file.html)

  `binary`

  :   **\[deprecated\]** Please use the `compare` argument instead.

  `cran`

  :   Should these expectations be verified on CRAN? By default, they
      are not, because snapshot tests tend to be fragile because they
      often rely on minor details of dependencies.

  `transform`

  :   Optionally, a function to scrub sensitive or stochastic text from
      the output. Should take a character vector of lines as input and
      return a modified character vector as output.

  `variant`

  :   If not-`NULL`, results will be saved in
      `_snaps/{variant}/{test}/{name}`. This allows you to create
      different snapshots for different scenarios, like different
      operating systems or different R versions.

      Note that there's no way to declare all possible variants up front
      which means that as soon as you start using variants, you are
      responsible for deleting snapshot variants that are no longer
      used. (testthat will still delete all variants if you delete the
      test.)

## Value

[NULL](https://rdrr.io/r/base/NULL.html) (from
[`testthat::expect_snapshot_file()`](https://testthat.r-lib.org/reference/expect_snapshot_file.html))

## Examples

``` r
if (FALSE) { # \dontrun{
expect_snapshot_data(iris, name = "iris")
} # }
```
