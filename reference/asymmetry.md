# Directional asymmetry between two groups

Measures how unevenly citations flow between two groups over time. For
each period, computes the mean share of within-set outgoing citations
that group \`from_group\` directs to group \`to_group\`, and the
reverse, and their ratio. A value far above one indicates that
\`from_group\` is much more attentive to \`to_group\` than vice versa.

## Usage

``` r
asymmetry(panel, from_group, to_group, smooth = 3L)
```

## Arguments

- panel:

  A \`citation_panel\` object.

- from_group:

  Character, a group label appearing in \`panel\$groups\`.

- to_group:

  Character, a group label appearing in \`panel\$groups\`. Must differ
  from \`from_group\`.

- smooth:

  Integer smoothing window. Default \`3L\`.

## Value

An object of class \`fragmentation_asymmetry\` with elements:

- series:

  Tibble with columns \`period\`, \`n_from\`, \`n_to\`,
  \`from_to_share\`, \`to_from_share\`, \`asymmetry_ratio\`, and
  \`asymmetry_ratio_smoothed\`.

- config:

  List of arguments used.

- panel:

  Input panel.

## Examples

``` r
if (FALSE) { # \dontrun{
data(criminology_panel)
asy <- asymmetry(criminology_panel, from_group = "Critical/Theoretical", to_group = "Quant/Empirical")
print(asy)
} # }
```
