# citefrag

<!-- badges: start -->
[![R-CMD-check](https://github.com/zvakhitova/citefrag/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/zvakhitova/citefrag/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R-CMD-check](https://github.com/zarina-vakhitova/citefrag/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/zarina-vakhitova/citefrag/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**citefrag** measures within-group versus between-group citation preference in longitudinal journal panels. It implements the pair-averaged fragmentation ratio, exact and Monte Carlo permutation tests, directional asymmetry analysis, a suite of robustness checks, and piecewise regression with bootstrap confidence intervals for locating structural breaks in ratio trajectories.

The package was developed to accompany Vakhitova (2026) on the fragmentation of criminology, but the machinery is general to any longitudinal node-by-node exchange network with a priori group labels. It works on journals grouped by research tradition, departments grouped by discipline, countries grouped by region, or any comparable setting where the question is whether nodes exchange more intensely with their own kind than across group boundaries.

## Installation

You can install the development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("zvakhitova/citefrag")
```

Once the package is on CRAN, installation will be:

``` r
install.packages("citefrag")
```

## Quick start

The package ships with a 23-journal criminology panel spanning 1960 to 2025, which gives you a real working example out of the box.

``` r
library(citefrag)
data(criminology_panel)

# Stage 1: compute the within-cluster to between-cluster ratio
fr <- fragmentation_ratio(criminology_panel, normalise = "row")
print(fr)
plot(fr)

# Stage 2: test statistical significance via permutation
pt <- fragmentation_test(criminology_panel, n_perm = 10000L, seed = 42L)
print(pt)

# Stage 3: locate the structural break
cp <- fragmentation_changepoint(fr, seed = 42L)
print(cp)
plot(cp)
```

For the complete walk-through of all functions applied to the bundled data, see the introductory vignette (`vignette("citefrag-intro")`).

## Input format

To apply `citefrag` to your own data, you need two things: a set of citation matrices indexed by time period, and a vector mapping each node to a group. Optionally you also need node sizes (for example, article counts) if you want to use the size-adjusted normalisations.

### What the constructor expects

The canonical input to `citation_panel()` is a named list of square numeric matrices, one per period, with identical row and column names. The entry `M[i, j]` is interpreted as the number of citations sent from node `i` to node `j` in that period. Nodes do not need to be present in every period; a node is considered active in period `t` if it appears in the rownames of `matrices[[t]]`. This lets the panel expand over time as new nodes enter, which is typical for citation networks where new journals emerge.

The group vector is a named character vector whose names match the node identifiers. Every node appearing in any matrix must have a group assignment.

The size vector, if supplied, can be either a single named numeric vector (when sizes are constant over time) or a named list of named numeric vectors keyed by period (when sizes vary over time, as article counts typically do).

### Worked example: from CSV to panel

Most users have citation data in long form, with one row per citing-cited-period triple. The helper `as_citation_panel()` converts this directly.

Suppose you have two CSV files:

``` 
citations.csv:
    period, from,      to,        value
    2018,   journal_A, journal_B, 45
    2018,   journal_A, journal_C, 12
    2018,   journal_B, journal_A, 23
    ...

journals.csv:
    journal,   group
    journal_A, Theory
    journal_B, Methods
    journal_C, Applied
    ...
```

Turning this into a `citation_panel` takes four lines:

``` r
edges <- read.csv("citations.csv")
meta  <- read.csv("journals.csv")
groups <- setNames(meta$group, meta$journal)
panel <- as_citation_panel(edges, groups = groups)

fragmentation_ratio(panel)
```

### Worked example: matrix-by-matrix construction

If you already have matrices (for example, because you constructed them from another data source), pass them directly:

``` r
M2018 <- matrix(c(0, 45, 12,
                  23,  0,  8,
                   5,  3,  0),
                nrow = 3, byrow = TRUE,
                dimnames = list(c("A","B","C"), c("A","B","C")))

M2019 <- M2018 + 1    # synthetic second year for illustration

panel <- citation_panel(
  matrices = list("2018" = M2018, "2019" = M2019),
  groups   = c(A = "Theory", B = "Methods", C = "Applied")
)
```

### Supplying node sizes for size-adjusted normalisations

For the `"target"` and `"article_pair"` normalisations, the package needs to know the size of each node in each period. If you have annual article counts, pass them as a list of named numeric vectors:

``` r
sizes <- list(
  "2018" = c(A = 180, B = 95, C = 42),
  "2019" = c(A = 175, B = 102, C = 48)
)

panel <- citation_panel(matrices, groups, sizes = sizes)
fragmentation_ratio(panel, normalise = "article_pair")
```

If you only pass `matrices` and `groups`, you can still use the `"raw"` and `"row"` normalisations, which do not require sizes.

## Function reference

The package exports eight functions. The first two construct the input object; the next four are the main analytical workflow; the last two are convenience helpers.

`citation_panel()` constructs a `citation_panel` object from a list of matrices, a group vector, and optional node sizes. Performs input validation.

`as_citation_panel()` is a convenience constructor that accepts a long-form edge list data frame instead of pre-built matrices.

`fragmentation_ratio()` computes the pair-averaged within-group to between-group citation ratio for each period, under one of four normalisations: raw, row-normalised, target-size adjusted, or article-pair normalised. Returns a time series with optional smoothing.

`fragmentation_test()` runs an exact or Monte Carlo permutation test against the null hypothesis of no within-group preference, holding the citation matrix and group sizes fixed and permuting the mapping from nodes to group labels.

`fragmentation_robustness()` recomputes the ratio series under alternative group specifications, restricted node subsets, or both, and reports correlations between each alternative and the baseline trajectory.

`fragmentation_changepoint()` fits a piecewise linear model with an unknown breakpoint to the ratio trajectory, using grid search to locate the breakpoint and bootstrap resampling to construct a confidence interval.

`asymmetry()` measures directional citation flow between two specified groups over time, reporting the share of each group's outgoing citations that goes to the other group and the ratio between them.

`fragmentation_analysis()` runs the full pipeline (ratio, test, robustness, changepoint) in one call and returns a list of the four result objects. Useful for reproducing a complete analysis.

Each function returns an object with `print()`, `plot()`, `summary()`, and `as.data.frame()` methods. Full argument documentation is in the help pages (for example, `?fragmentation_ratio`).

## When to use citefrag, and when not

`citefrag` is narrow by design. It does one thing (measure longitudinal within-group versus between-group preference with associated inferential machinery) and it does not try to do much else. Other packages cover adjacent ground, and it is worth naming them so you choose the right tool.

For general bibliometric analysis (co-citation networks, collaboration maps, author productivity, thematic mapping, Lotka's law), use **bibliometrix** (Aria and Cuccurullo 2017). It is the comprehensive workhorse of R-based scientometrics and covers enormously more ground than `citefrag` does.

For cross-sectional network segregation measures on a single network (E-I index, Freeman's segregation index, assortativity coefficients), use **netseg** (Bojanowski). The E-I index in particular is the classic within-between contrast, and it is a fine tool if your data is a single network rather than a longitudinal panel and you do not need the specific statistical scaffolding `citefrag` provides.

For low-level network operations (modularity, assortativity, community detection, centrality measures), use **igraph** (Csárdi and Nepusz). Most specialised network packages, including `citefrag` internally, build on it.

`citefrag` is the right tool when your question is specifically: does the within-group preference in this network change over time, is the change statistically distinguishable from chance, is it robust to how I drew the group boundaries, and is there a structural break? If any of those four questions is central to your analysis, the package is built for it. If your question is about network structure more broadly, or about a single-period network, one of the tools above is probably a better fit.

## Mathematical background

For a citation matrix $C^{(t)}$ observed in period $t$, with each node $i$ assigned to a group $g(i)$, the pair-averaged within-between ratio is

$$R(t) = \frac{\frac{1}{|W_t|} \sum_{(i,j) \in W_t} C^{(t)}_{ij}}{\frac{1}{|B_t|} \sum_{(i,j) \in B_t} C^{(t)}_{ij}}$$

where $W_t = \{(i,j) : g(i) = g(j),\ i \neq j\}$ is the set of directed within-group pairs active in period $t$, and $B_t = \{(i,j) : g(i) \neq g(j)\}$ is the set of directed between-group pairs. Self-citations are excluded. A value of $R(t) = 1$ indicates no within-group preference; values above one indicate that nodes cite within their own group more intensely than they cite across group boundaries.

Four normalisations of $C^{(t)}$ are supported. The raw variant uses counts as supplied. The row-normalised variant divides each row by its sum, giving every citing node equal weight regardless of its publication volume. The target-size variant additionally divides each cell by the size of the cited node before row-normalising. The article-pair variant uses $\Omega_{ij} = C_{ij} / (n_i \cdot n_j)$ directly, removing size effects on both sides simultaneously.

The permutation test holds $C^{(t)}$ and the group-size vector fixed, permutes the mapping from nodes to labels, and computes the null distribution of $R(t)$ under random assignment. When the number of distinct permutations is feasible to enumerate, the test is exact; otherwise it is approximated by Monte Carlo sampling.

The changepoint procedure fits a continuous two-segment linear model with a grid-searched breakpoint, and bounds the breakpoint via nonparametric bootstrap over the observation pairs.

## How to cite

If you use `citefrag` in published work, please cite both the package and the paper it accompanies.

``` r
citation("citefrag")
```

In BibTeX:

``` bibtex
@Manual{vakhitova2026citefrag,
  title   = {citefrag: Measuring Fragmentation in Longitudinal Citation Networks},
  author  = {Zarina Vakhitova},
  year    = {2026},
  note    = {R package version 0.1.0},
  url     = {https://github.com/zvakhitova/citefrag}
}

@Article{vakhitova2026fragmentation,
  title   = {The Fragmentation of Criminology: A Longitudinal Citation Network Analysis},
  author  = {Zarina Vakhitova},
  year    = {2026},
  note    = {Manuscript in preparation}
}
```

## Related references

Aria, M., and Cuccurullo, C. (2017). bibliometrix: An R-tool for comprehensive science mapping analysis. *Journal of Informetrics*, 11(4), 959-975.

Bojanowski, M. netseg: Measures of network segregation and homophily. R package. <https://mbojan.github.io/netseg/>

Csárdi, G., and Nepusz, T. (2006). The igraph software package for complex network research. *InterJournal, Complex Systems*, 1695.

## Bug reports and feature requests

Please report bugs and request features on the [GitHub issues page](https://github.com/zvakhitova/citefrag/issues). Pull requests are welcome.

## License

MIT
