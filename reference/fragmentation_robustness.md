# Robustness checks for the fragmentation ratio

Recomputes the ratio series under alternative group specifications or
restricted node subsets, and compares each alternative to the baseline.
This is the function that answers "does the trajectory depend on my
specific cluster assignment?" and "does it depend on which nodes I
include?".

## Usage

``` r
fragmentation_robustness(
  panel,
  alternatives = NULL,
  subpanels = NULL,
  normalise = c("raw", "row", "target", "article_pair"),
  smooth = 3L
)
```

## Arguments

- panel:

  A \`citation_panel\` object, representing the baseline specification.

- alternatives:

  Optional named list of alternative group vectors. Each element must be
  a named character vector with the same node identifiers as
  \`panel\$groups\`, but possibly with different group labels. For
  example, \`list(merge_A_B = c(j1 = "X", j2 = "X", j3 = "Y"))\`.

- subpanels:

  Optional named list of node subsets. Each element is a character
  vector of node identifiers to retain. The ratio is recomputed on each
  subpanel using only those nodes.

- normalise:

  Character, as in \[fragmentation_ratio()\]. Default \`"raw"\`.

- smooth:

  Integer smoothing window. Default \`3L\`.

## Value

An object of class \`fragmentation_robustness\` with elements:

- series:

  Tibble with columns \`specification\`, \`period\`, \`ratio\`, and
  \`ratio_smoothed\`, long-form across all specifications (baseline plus
  alternatives plus subpanels).

- correlations:

  Tibble with one row per non-baseline specification, columns
  \`specification\`, \`r_raw\`, \`r_smooth\`: the correlation with the
  baseline ratio and with the smoothed baseline ratio.

- config:

  List of arguments used.

- panel:

  Input panel.

## See also

\[fragmentation_ratio()\].

## Examples

``` r
if (FALSE) { # \dontrun{
data(criminology_panel)
# Alternative specification: merge two groups into one
g0 <- criminology_panel$groups
alt <- g0; alt[alt == "Intl/Comparative"] <- "Critical/Theoretical"
rb <- fragmentation_robustness(
  criminology_panel,
  alternatives = list(merged_crit_intl = alt)
)
print(rb)
plot(rb)
} # }
```
