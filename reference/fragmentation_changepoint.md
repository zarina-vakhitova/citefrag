# Piecewise linear regression with bootstrap confidence interval

Fits a two-segment linear model with an unknown breakpoint to a
fragmentation ratio time series. The breakpoint is located by grid
search minimising residual sum of squares; a bootstrap confidence
interval is obtained by resampling the observation pairs.

## Usage

``` r
fragmentation_changepoint(
  x,
  value_column = "ratio_smoothed",
  min_edge_gap = 5L,
  n_boot = 1000L,
  seed = NULL
)
```

## Arguments

- x:

  Either a \`fragmentation_ratio\` object, or a data frame with columns
  \`period\` and \`value\` (in which case \`value\` is the smoothed or
  unsmoothed ratio).

- value_column:

  When \`x\` is a \`fragmentation_ratio\`, the column of \`x\$series\`
  to fit. Default \`"ratio_smoothed"\`. Use \`"ratio"\` to fit the
  unsmoothed series.

- min_edge_gap:

  Integer, the number of periods at each end of the series excluded from
  candidate breakpoints. Default \`5L\`.

- n_boot:

  Integer, number of bootstrap replications for the breakpoint
  confidence interval. Default \`1000L\`.

- seed:

  Optional integer seed. Default \`NULL\`.

## Value

An object of class \`fragmentation_changepoint\` with elements:

- breakpoint:

  Estimated breakpoint period.

- ci:

  Named numeric vector of length two: \`lo\` and \`hi\` (2.5th and
  97.5th bootstrap percentiles).

- slope_before:

  Pre-breakpoint slope (change in ratio per period).

- slope_after:

  Post-breakpoint slope.

- p_before, p_after:

  Two-sided p-values from the piecewise fit.

- r_squared:

  Fit \\R^2\\.

- fitted:

  Tibble with columns \`period\`, \`observed\`, \`fitted\`.

- config:

  List of arguments used.

## Details

The piecewise model is parameterised as \$\$y_t = \beta_0 + \beta_1 (t -
bp) \cdot \mathbb{1}(t \leq bp) + \beta_2 (t - bp) \cdot \mathbb{1}(t \>
bp) + \varepsilon_t\$\$ which produces a continuous fit with separate
slopes either side of the breakpoint. The breakpoint is chosen as the
integer period in the interior of the series that minimises the residual
sum of squares.

## Examples

``` r
if (FALSE) { # \dontrun{
data(criminology_panel)
fr <- fragmentation_ratio(criminology_panel, normalise = "row")
cp <- fragmentation_changepoint(fr, seed = 42L)
print(cp)
plot(cp)
} # }
```
