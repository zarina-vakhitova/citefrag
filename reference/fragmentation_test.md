# Permutation test for the fragmentation ratio

Tests whether the observed within-between ratio exceeds what would be
obtained under random assignment of nodes to groups of the same sizes.
For small label sets (where the number of distinct permutations is at or
below \`exact_threshold\`) the test is exact; otherwise it is
approximated by Monte Carlo sampling.

## Usage

``` r
fragmentation_test(
  panel,
  n_perm = 10000L,
  exact_threshold = 1000L,
  normalise = c("raw", "row", "target", "article_pair"),
  seed = NULL
)
```

## Arguments

- panel:

  A \`citation_panel\` object.

- n_perm:

  Integer, number of Monte Carlo permutations when exact enumeration is
  infeasible. Default \`10000L\`.

- exact_threshold:

  Integer. If the number of distinct permutations of the group labels is
  at or below this value, the test is carried out by exact enumeration
  rather than Monte Carlo. Default \`1000L\`.

- normalise:

  Character, one of \`"raw"\`, \`"row"\`, \`"target"\`,
  \`"article_pair"\`. Default \`"raw"\`.

- seed:

  Optional integer seed for reproducibility of the Monte Carlo sampling.
  Default \`NULL\`.

## Value

An object of class \`fragmentation_test\` (inheriting from
\`citefrag_result\`), a list with elements:

- results:

  Tibble with one row per period: \`period\`, \`n_nodes\`, \`observed\`,
  \`null_mean\`, \`null_sd\`, \`null_q05\`, \`null_q95\`, \`null_q99\`,
  \`z\`, \`p_value\`, \`method\` ("exact" or "monte_carlo"), and
  \`n_distinct_perms\`.

- config:

  List of arguments used.

- panel:

  Input panel.

## Details

The null hypothesis is that the observed pattern of within-group
preference could be produced by chance, given the fixed group sizes and
the observed citation matrix. The test holds the group sizes and the
citation matrix fixed and permutes the mapping from nodes to group
labels; for each permutation, the ratio is recomputed. The z-score is
\\(R\_{obs} - \bar{R}\_{null}) / \mathrm{sd}(R\_{null})\\; the p-value
is the proportion of null ratios at least as extreme as the observed.

Periods with fewer than four active nodes, or with fewer than two groups
of size at least two, are skipped.

## See also

\[fragmentation_ratio()\], \[fragmentation_robustness()\].

## Examples

``` r
if (FALSE) { # \dontrun{
data(criminology_panel)
pt <- fragmentation_test(criminology_panel, n_perm = 1000L, seed = 42L)
print(pt)
} # }
```
