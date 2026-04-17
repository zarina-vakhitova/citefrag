#' Construct a citation panel object
#'
#' Creates a validated `citation_panel` object that bundles annual citation
#' matrices, group assignments, and optional node size information. This
#' object is the standard input to all analysis functions in citefrag.
#'
#' @param matrices A named list of square citation matrices, one per period.
#'   List names are period identifiers (typically years as character
#'   strings). Each matrix must be numeric, square, with identical row and
#'   column names. The entry `M[i, j]` is interpreted as the number of
#'   citations from node `i` to node `j` in that period.
#' @param groups A named character vector mapping node identifiers to group
#'   labels. The names must cover every node appearing in any matrix in
#'   `matrices`. Nodes not listed in `groups` will trigger an error.
#' @param sizes Optional node size information for size-adjusted
#'   normalisations. Either a named numeric vector (time-invariant sizes,
#'   names matching the union of nodes) or a named list of named numeric
#'   vectors keyed by period identifiers (time-varying sizes, such as
#'   annual article counts). Default `NULL`.
#'
#' @return An object of class `citation_panel`: a list with elements
#'   `matrices`, `groups`, `sizes`, `periods`, `nodes`, `n_periods`,
#'   `n_nodes`, and `n_groups`.
#'
#' @examples
#' \dontrun{
#' # Using bundled criminology data
#' data(criminology_panel)
#' print(criminology_panel)
#' }
#'
#' @export
citation_panel <- function(matrices, groups, sizes = NULL) {
  
  ## ---- validation -----------------------------------------------------
  if (!is.list(matrices) || length(matrices) == 0L)
    stop("`matrices` must be a non-empty list.", call. = FALSE)
  if (is.null(names(matrices)) || any(names(matrices) == ""))
    stop("`matrices` must be named (names are period identifiers).",
         call. = FALSE)
  if (is.null(names(groups)))
    stop("`groups` must be a named vector (names are node identifiers).",
         call. = FALSE)
  
  # Validate each matrix individually
  for (p in names(matrices)) {
    M <- matrices[[p]]
    if (!is.matrix(M) || !is.numeric(M))
      stop(sprintf("matrices[['%s']] is not a numeric matrix.", p),
           call. = FALSE)
    if (nrow(M) != ncol(M))
      stop(sprintf("matrices[['%s']] is not square.", p), call. = FALSE)
    rn <- rownames(M); cn <- colnames(M)
    if (is.null(rn) || is.null(cn) || !identical(rn, cn))
      stop(sprintf("matrices[['%s']] must have identical row and column names.", p),
           call. = FALSE)
  }
  
  # All nodes across all matrices must be covered by groups
  all_nodes <- unique(unlist(lapply(matrices, rownames)))
  missing_nodes <- setdiff(all_nodes, names(groups))
  if (length(missing_nodes) > 0L)
    stop(sprintf("Nodes missing from `groups`: %s",
                 paste(missing_nodes, collapse = ", ")), call. = FALSE)
  
  # Validate sizes if supplied
  if (!is.null(sizes)) {
    if (is.list(sizes) && !is.numeric(sizes)) {
      # Time-varying: list of named numeric vectors, keyed by period
      bad <- setdiff(names(matrices), names(sizes))
      if (length(bad) > 0L)
        stop(sprintf("`sizes` is missing entries for periods: %s",
                     paste(bad, collapse = ", ")), call. = FALSE)
    } else if (is.numeric(sizes)) {
      # Time-invariant: single named numeric vector
      if (is.null(names(sizes)))
        stop("`sizes` must be named when supplied as a numeric vector.",
             call. = FALSE)
    } else {
      stop("`sizes` must be NULL, a named numeric vector, or a named list of ",
           "named numeric vectors.", call. = FALSE)
    }
  }
  
  ## ---- construct ------------------------------------------------------
  out <- list(
    matrices  = matrices,
    groups    = groups,
    sizes     = sizes,
    periods   = names(matrices),
    nodes     = all_nodes,
    n_periods = length(matrices),
    n_nodes   = length(all_nodes),
    n_groups  = length(unique(groups))
  )
  class(out) <- "citation_panel"
  out
}


#' @export
print.citation_panel <- function(x, ...) {
  cat("<citation_panel>\n")
  cat(sprintf("  Periods: %d  (%s to %s)\n",
              x$n_periods,
              x$periods[1L],
              x$periods[x$n_periods]))
  cat(sprintf("  Nodes:   %d\n", x$n_nodes))
  cat(sprintf("  Groups:  %d  (%s)\n",
              x$n_groups,
              paste(unique(x$groups), collapse = ", ")))
  cat(sprintf("  Sizes:   %s\n",
              if (is.null(x$sizes)) "not supplied"
              else if (is.list(x$sizes) && !is.numeric(x$sizes)) "time-varying"
              else "time-invariant"))
  invisible(x)
}


#' @export
summary.citation_panel <- function(object, ...) {
  cat("<citation_panel> summary\n")
  cat(sprintf("  %d periods, %d nodes, %d groups\n\n",
              object$n_periods, object$n_nodes, object$n_groups))
  cat("Group composition:\n")
  tab <- table(object$groups)
  for (g in names(tab))
    cat(sprintf("  %-25s %d\n", g, tab[[g]]))
  cat("\nPer-period node counts:\n")
  for (p in object$periods) {
    n <- length(rownames(object$matrices[[p]]))
    cat(sprintf("  %s: %d nodes\n", p, n))
  }
  invisible(object)
}


#' Convert an edge-list data frame to a citation_panel
#'
#' Convenience helper for users who have citation data in long form rather
#' than as a list of matrices. The input should have one row per
#' `(period, from_node, to_node)` triple, with a numeric value column.
#'
#' @param x A data frame with columns `period`, `from`, `to`, and `value`.
#'   Any additional columns are ignored. The `period` column may be numeric
#'   or character; it will be coerced to character for indexing.
#' @param groups Named character vector mapping node identifiers to group
#'   labels, as in [citation_panel()].
#' @param sizes Optional, as in [citation_panel()].
#'
#' @return A `citation_panel` object.
#' @export
as_citation_panel <- function(x, groups, sizes = NULL) {
  if (!is.data.frame(x))
    stop("`x` must be a data frame.", call. = FALSE)
  required <- c("period", "from", "to", "value")
  if (!all(required %in% names(x)))
    stop("`x` must contain columns: period, from, to, value.", call. = FALSE)
  
  all_nodes <- sort(unique(c(as.character(x$from), as.character(x$to))))
  periods <- sort(unique(as.character(x$period)))
  
  matrices <- lapply(periods, function(p) {
    sub <- x[as.character(x$period) == p, , drop = FALSE]
    M <- matrix(0, nrow = length(all_nodes), ncol = length(all_nodes),
                dimnames = list(all_nodes, all_nodes))
    for (i in seq_len(nrow(sub))) {
      M[as.character(sub$from[i]), as.character(sub$to[i])] <-
        M[as.character(sub$from[i]), as.character(sub$to[i])] + sub$value[i]
    }
    M
  })
  names(matrices) <- periods
  
  citation_panel(matrices, groups, sizes)
}
