# Internal normalisation helpers for citation matrices.
# Not exported. Used by fragmentation_ratio() and fragmentation_test().

#' Row-normalise a citation matrix
#'
#' Divides each row by its sum so that every row sums to 1 (where non-zero).
#' Interprets rows as distributions of outgoing attention.
#'
#' @param M numeric square matrix.
#' @return matrix of the same dimension with rows summing to 1 (or 0 if row
#'   was entirely zero).
#' @keywords internal
#' @noRd
.row_normalise <- function(M) {
  rs <- rowSums(M)
  rs_safe <- ifelse(rs == 0, 1, rs)
  M / rs_safe
}


#' Target-size normalise a citation matrix
#'
#' Divides each cell by the size (for example, article count) of the cited
#' node before row-normalising. Controls for differences in publication
#' volume of cited outlets.
#'
#' @param M numeric square matrix.
#' @param sizes numeric vector of node sizes, length equal to ncol(M),
#'   in the same order as the columns of M.
#' @return matrix of the same dimension.
#' @keywords internal
#' @noRd
.target_normalise <- function(M, sizes) {
  n_safe <- ifelse(sizes == 0, 1, sizes)
  col_normed <- sweep(M, 2, n_safe, "/")
  .row_normalise(col_normed)
}


#' Article-pair normalise a citation matrix
#'
#' Divides each cell by the product of citing and cited node sizes,
#' producing expected citations per article pair. Controls for size on both
#' sides simultaneously; used without further row-normalisation. Diagonal
#' is set to zero.
#'
#' @param M numeric square matrix.
#' @param sizes numeric vector of node sizes.
#' @return matrix of the same dimension.
#' @keywords internal
#' @noRd
.article_pair_normalise <- function(M, sizes) {
  n_safe <- ifelse(sizes == 0, 1, sizes)
  denom <- outer(n_safe, n_safe, "*")
  out <- M / denom
  diag(out) <- 0
  out
}


#' Apply a normalisation to a citation matrix
#'
#' Dispatches to the appropriate internal helper.
#'
#' @param M numeric square matrix.
#' @param method one of "raw", "row", "target", "article_pair".
#' @param sizes optional numeric vector, required if method is "target" or
#'   "article_pair".
#' @return normalised matrix.
#' @keywords internal
#' @noRd
.normalise_matrix <- function(M, method, sizes = NULL) {
  method <- match.arg(method, c("raw", "row", "target", "article_pair"))
  if (method %in% c("target", "article_pair") && is.null(sizes))
    stop(sprintf("Normalisation '%s' requires `sizes`.", method),
         call. = FALSE)
  switch(method,
         raw          = M,
         row          = .row_normalise(M),
         target       = .target_normalise(M, sizes),
         article_pair = .article_pair_normalise(M, sizes))
}


#' Extract sizes for a given period from a citation_panel
#'
#' Handles the three cases: no sizes, time-invariant sizes, or
#' time-varying sizes. Returns a numeric vector aligned with the nodes
#' active in that period.
#'
#' @keywords internal
#' @noRd
.sizes_for_period <- function(panel, period, active_nodes) {
  if (is.null(panel$sizes)) return(NULL)
  if (is.list(panel$sizes) && !is.numeric(panel$sizes)) {
    s <- panel$sizes[[period]]
  } else {
    s <- panel$sizes
  }
  s[active_nodes]
}
