# Criminology journal citation panel, 1960-2025

A `citation_panel` object bundling annual citation matrices, group
assignments, and annual article counts for 23 criminology journals
spanning 1960 to 2025. Constructed from Web of Science article-level
records, with cited references parsed and matched to journal
identifiers.

## Usage

``` r
criminology_panel
```

## Format

A `citation_panel` object with:

- matrices:

  Named list of 66 annual citation matrices, 1960-2025. Each matrix
  contains only the journals active in that year.

- groups:

  Named character vector of length 23 assigning each journal to one of
  four traditions: `"Quant/Empirical"`, `"Applied/Practice"`,
  `"Intl/Comparative"`, or `"Critical/Theoretical"`.

- sizes:

  Named list of 66 numeric vectors giving annual article counts for each
  journal, used for size-adjusted normalisations.

## Source

Vakhitova, Z. (2026). The fragmentation of criminology: a longitudinal
citation network analysis.

## Examples

``` r
# \donttest{
data(criminology_panel)
print(criminology_panel)
#> <citation_panel>
#>   Periods: 66  (1960 to 2025)
#>   Nodes:   23
#>   Groups:  4  (Quant/Empirical, Applied/Practice, Intl/Comparative, Critical/Theoretical)
#>   Sizes:   time-varying
# }
```
