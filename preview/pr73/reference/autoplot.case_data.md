# Plot case data

Plot case data

## Usage

``` r
# S3 method for class 'case_data'
autoplot(object, log_y = TRUE, log_x = FALSE, ...)
```

## Arguments

- object:

  a `case_data` object

- log_y:

  whether to log-transform the y-axis

- log_x:

  whether to log-transform the x-axis

- ...:

  Arguments passed on to
  [`ggplot2::geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html),
  [`ggplot2::geom_line`](https://ggplot2.tidyverse.org/reference/geom_path.html)

  `mapping`

  :   Set of aesthetic mappings created by
      [`aes()`](https://ggplot2.tidyverse.org/reference/aes.html). If
      specified and `inherit.aes = TRUE` (the default), it is combined
      with the default mapping at the top level of the plot. You must
      supply `mapping` if there is no plot mapping.

  `data`

  :   The data to be displayed in this layer. There are three options:

      - `NULL` (default): the data is inherited from the plot data as
        specified in the call to
        [`ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html).

      - A `data.frame`, or other object, will override the plot data.
        All objects will be fortified to produce a data frame. See
        [`fortify()`](https://ggplot2.tidyverse.org/reference/fortify.html)
        for which variables will be created.

      - A `function` will be called with a single argument, the plot
        data. The return value must be a `data.frame`, and will be used
        as the layer data. A `function` can be created from a `formula`
        (e.g. `~ head(.x, 10)`).

  `stat`

  :   The statistical transformation to use on the data for this layer.
      When using a `geom_*()` function to construct a layer, the `stat`
      argument can be used to override the default coupling between
      geoms and stats. The `stat` argument accepts the following:

      - A `Stat` ggproto subclass, for example `StatCount`.

      - A string naming the stat. To give the stat as a string, strip
        the function name of the `stat_` prefix. For example, to use
        `stat_count()`, give the stat as `"count"`.

      - For more information and other ways to specify the stat, see the
        [layer
        stat](https://ggplot2.tidyverse.org/reference/layer_stats.html)
        documentation.

  `position`

  :   A position adjustment to use on the data for this layer. This can
      be used in various ways, including to prevent overplotting and
      improving the display. The `position` argument accepts the
      following:

      - The result of calling a position function, such as
        `position_jitter()`. This method allows for passing extra
        arguments to the position.

      - A string naming the position adjustment. To give the position as
        a string, strip the function name of the `position_` prefix. For
        example, to use `position_jitter()`, give the position as
        `"jitter"`.

      - For more information and other ways to specify the position, see
        the [layer
        position](https://ggplot2.tidyverse.org/reference/layer_positions.html)
        documentation.

  `na.rm`

  :   If `FALSE`, the default, missing values are removed with a
      warning. If `TRUE`, missing values are silently removed.

  `show.legend`

  :   Logical. Should this layer be included in the legends? `NA`, the
      default, includes if any aesthetics are mapped. `FALSE` never
      includes, and `TRUE` always includes. It can also be a named
      logical vector to finely select the aesthetics to display. To
      include legend keys for all levels, even when no data exists, use
      `TRUE`. If `NA`, all levels are shown in legend, but unobserved
      levels are omitted.

  `inherit.aes`

  :   If `FALSE`, overrides the default aesthetics, rather than
      combining with them. This is most useful for helper functions that
      define both data and aesthetics and shouldn't inherit behaviour
      from the default plot specification, e.g.
      [`annotation_borders()`](https://ggplot2.tidyverse.org/reference/annotation_borders.html).

  `arrow`

  :   Arrow specification. Can be created by
      [`grid::arrow()`](https://rdrr.io/r/grid/arrow.html) or `NULL` to
      not draw an arrow.

  `arrow.fill`

  :   Fill colour to use for closed arrowheads. `NULL` means use
      `colour` aesthetic.

  `lineend`

  :   Line end style, one of `"round"`, `"butt"` or `"square"`.

  `linejoin`

  :   Line join style, one of `"round"`, `"mitre"` or `"bevel"`.

  `linemitre`

  :   Line mitre limit, a number greater than 1.

  `orientation`

  :   The orientation of the layer. The default (`NA`) automatically
      determines the orientation from the aesthetic mapping. In the rare
      event that this fails it can be given explicitly by setting
      `orientation` to either `"x"` or `"y"`. See the *Orientation*
      section for more detail.

## Value

a [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)

## Examples

``` r
set.seed(1)
sim_case_data <-
  serocalculator::typhoid_curves_nostrat_100 |>
  sim_case_data(n = 5, max_n_obs = 20, followup_interval = 14)

sim_case_data |>
  autoplot(alpha = .5)
```
