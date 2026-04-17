# citefrag: Measuring Fragmentation in Longitudinal Citation Networks

The citefrag package provides tools for measuring within-group versus
between-group citation preference in longitudinal journal panels. It
implements the pair-averaged fragmentation ratio with several
normalisations, exact and Monte Carlo permutation tests, directional
asymmetry analysis, a suite of robustness checks, and piecewise
regression with bootstrap confidence intervals for locating structural
breaks in ratio trajectories.

## Typical workflow

Construct a \[citation_panel()\] object from a list of annual citation
matrices and a group vector. Compute the ratio series with
\[fragmentation_ratio()\]. Test its statistical significance with
\[fragmentation_test()\]. Check robustness with
\[fragmentation_robustness()\]. Detect structural breaks with
\[fragmentation_changepoint()\]. Each function returns an object with
\`print()\`, \`plot()\`, \`summary()\`, and \`as.data.frame()\` methods.

The convenience wrapper \[fragmentation_analysis()\] runs the full
pipeline in one call and returns a list of the four result objects.

## The fragmentation ratio

For a citation matrix \\C^{(t)}\\ observed in period \\t\\, with each
node \\i\\ assigned to a group \\g(i)\\, the pair-averaged
within-between ratio is \$\$R(t) = \frac{\frac{1}{\|W_t\|}\sum\_{(i,j)
\in W_t} C^{(t)}\_{ij}} {\frac{1}{\|B_t\|}\sum\_{(i,j) \in B_t}
C^{(t)}\_{ij}}\$\$ where \\W_t\\ is the set of directed within-group
pairs and \\B_t\\ is the set of directed between-group pairs.
Self-citations are excluded. A value of \\R(t) = 1\\ indicates no
within-group preference; values above one indicate that nodes cite
within their own group more intensely than across group boundaries.

## References

Vakhitova, Z. (2026). The fragmentation of criminology: a longitudinal
citation network analysis. \*Manuscript in preparation.\*

## See also

Useful links:

- <https://zarina-vakhitova.github.io/citefrag>

- <https://github.com/zarina-vakhitova/citefrag>

- <https://zarina-vakhitova.github.io/citefrag/>

- Report bugs at <https://github.com/zvakhitova/citefrag/issues>

## Author

**Maintainer**: Zarina Vakhitova <zarina.vakhitova@deakin.edu.au>
([ORCID](https://orcid.org/0000-0002-2853-7968))
