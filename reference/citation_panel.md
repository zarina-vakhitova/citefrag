# Construct a citation panel object

Creates a validated \`citation_panel\` object that bundles annual
citation matrices, group assignments, and optional node size
information. This object is the standard input to all analysis functions
in citefrag.

## Usage

``` r
citation_panel(matrices, groups, sizes = NULL)
```

## Arguments

- matrices:

  A named list of square citation matrices, one per period. List names
  are period identifiers (typically years as character strings). Each
  matrix must be numeric, square, with identical row and column names.
  The entry \`M\[i, j\]\` is interpreted as the number of citations from
  node \`i\` to node \`j\` in that period.

- groups:

  A named character vector mapping node identifiers to group labels. The
  names must cover every node appearing in any matrix in \`matrices\`.
  Nodes not listed in \`groups\` will trigger an error.

- sizes:

  Optional node size information for size-adjusted normalisations.
  Either a named numeric vector (time-invariant sizes, names matching
  the union of nodes) or a named list of named numeric vectors keyed by
  period identifiers (time-varying sizes, such as annual article
  counts). Default \`NULL\`.

## Value

An object of class \`citation_panel\`: a list with elements
\`matrices\`, \`groups\`, \`sizes\`, \`periods\`, \`nodes\`,
\`n_periods\`, \`n_nodes\`, and \`n_groups\`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Using bundled criminology data
data(criminology_panel)
print(criminology_panel)
} # }
```
