# Run the full fragmentation analysis pipeline

Convenience wrapper that runs \[fragmentation_ratio()\],
\[fragmentation_test()\], \[fragmentation_robustness()\], and
\[fragmentation_changepoint()\] in sequence, returning a list of the
four result objects. Useful for reproducing a complete analysis in a
single call, for example in a replication vignette.

## Usage

``` r
fragmentation_analysis(
  panel,
  normalise = c("raw", "row", "target", "article_pair"),
  smooth = 3L,
  n_perm = 10000L,
  alternatives = NULL,
  subpanels = NULL,
  seed = NULL,
  verbose = TRUE
)
```

## Arguments

- panel:

  A \`citation_panel\` object.

- normalise:

  Character, as in \[fragmentation_ratio()\]. Default \`"raw"\`.

- smooth:

  Integer smoothing window. Default \`3L\`.

- n_perm:

  Integer, number of Monte Carlo permutations. Default \`10000L\`.

- alternatives:

  Optional named list of alternative group vectors. Default \`NULL\`, in
  which case no robustness check against alternative groupings is
  carried out.

- subpanels:

  Optional named list of node subsets. Default \`NULL\`.

- seed:

  Optional integer seed. Default \`NULL\`.

- verbose:

  Logical, print progress messages. Default \`TRUE\`.

## Value

A named list with elements \`ratio\`, \`test\`, \`robustness\`, and
\`changepoint\`. \`robustness\` is \`NULL\` when neither
\`alternatives\` nor \`subpanels\` are supplied.

## Examples

``` r
if (FALSE) { # \dontrun{
data(criminology_panel)
res <- fragmentation_analysis(criminology_panel, seed = 42L)
plot(res$ratio)
plot(res$changepoint)
} # }
```
