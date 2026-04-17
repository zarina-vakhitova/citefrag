# Convert an edge-list data frame to a citation_panel

Convenience helper for users who have citation data in long form rather
than as a list of matrices. The input should have one row per \`(period,
from_node, to_node)\` triple, with a numeric value column.

## Usage

``` r
as_citation_panel(x, groups, sizes = NULL)
```

## Arguments

- x:

  A data frame with columns \`period\`, \`from\`, \`to\`, and \`value\`.
  Any additional columns are ignored. The \`period\` column may be
  numeric or character; it will be coerced to character for indexing.

- groups:

  Named character vector mapping node identifiers to group labels, as in
  \[citation_panel()\].

- sizes:

  Optional, as in \[citation_panel()\].

## Value

A \`citation_panel\` object.
