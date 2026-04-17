#' Criminology journal citation panel, 1960-2025
#'
#' A \code{citation_panel} object bundling annual citation matrices, group
#' assignments, and annual article counts for 23 criminology journals
#' spanning 1960 to 2025. Constructed from Web of Science article-level
#' records, with cited references parsed and matched to journal
#' identifiers.
#'
#' @format A \code{citation_panel} object with:
#' \describe{
#'   \item{matrices}{Named list of 66 annual citation matrices,
#'     1960-2025. Each matrix contains only the journals active in that
#'     year.}
#'   \item{groups}{Named character vector of length 23 assigning each
#'     journal to one of four traditions: \code{"Quant/Empirical"},
#'     \code{"Applied/Practice"}, \code{"Intl/Comparative"}, or
#'     \code{"Critical/Theoretical"}.}
#'   \item{sizes}{Named list of 66 numeric vectors giving annual
#'     article counts for each journal, used for size-adjusted
#'     normalisations.}
#' }
#'
#' @source Vakhitova, Z. (2026). The fragmentation of criminology: a
#'   longitudinal citation network analysis.
#'
#' @examples
#' \donttest{
#' data(criminology_panel)
#' print(criminology_panel)
#' }
"criminology_panel"


#' Alternative cluster specifications for the criminology panel
#'
#' A named list of three alternative group-assignment vectors for the
#' journals in \code{criminology_panel}. Used to test sensitivity of
#' the fragmentation ratio to cluster specification.
#'
#' @format Named list with three elements, each a named character
#'   vector:
#' \describe{
#'   \item{\code{merge_cd_to_quant}}{Reassigns \emph{Crime &
#'     Delinquency} from the applied/practice cluster to the
#'     quantitative/empirical cluster.}
#'   \item{\code{merge_ps_to_applied}}{Reassigns \emph{Punishment
#'     & Society} from the critical/theoretical cluster to the
#'     applied/practice cluster.}
#'   \item{\code{merge_cjc_to_applied}}{Reassigns \emph{Criminology
#'     & Criminal Justice} from the international/comparative cluster
#'     to the applied/practice cluster.}
#' }
#'
#' @source Vakhitova (2026), Supplementary Materials.
"criminology_alternatives"
