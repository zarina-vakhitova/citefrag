# Core internal helpers used throughout the package.

#' Three-period centred moving average
#'
#' Smoothes a numeric vector using a three-period centred window. Ignores
#' NA values within each window; if fewer than two non-NA values are
#' available the output for that position is NA.
#'
#' @param x numeric vector.
#' @return smoothed numeric vector of the same length.
#' @keywords internal
#' @noRd
.smooth3 <- function(x) {
  n <- length(x)
  if (n == 0L) return(x)
  s <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    lo <- max(1L, i - 1L); hi <- min(n, i + 1L)
    vals <- x[lo:hi]; vals <- vals[!is.na(vals)]
    if (length(vals) >= 2L) s[i] <- mean(vals)
  }
  s
}


#' Pair-averaged within/between ratio from a matrix and label vector
#'
#' Core statistical computation. Self-citations (diagonal) are excluded.
#' Returns NA if there are no within-group pairs or no between-group pairs.
#'
#' @param M numeric square matrix.
#' @param labels character vector of group labels, length matching
#'   nrow(M) = ncol(M).
#' @return scalar, the ratio R.
#' @keywords internal
#' @noRd
.ratio_core <- function(M, labels) {
  n <- length(labels)
  same <- outer(labels, labels, "==")
  diag_mask <- diag(TRUE, n)
  within_mask  <- same & !diag_mask
  between_mask <- !same & !diag_mask
  wp <- sum(within_mask); bp <- sum(between_mask)
  if (wp == 0L || bp == 0L) return(NA_real_)
  wc <- sum(M[within_mask])
  bc <- sum(M[between_mask])
  (wc / wp) / max(bc / bp, 1e-10)
}


#' Multinomial coefficient for label sizes
#'
#' Number of distinct permutations of a label vector with the given size
#' vector. Uses log-factorials to avoid overflow.
#'
#' @param sizes integer vector of group sizes.
#' @return integer count.
#' @keywords internal
#' @noRd
.multinomial_count <- function(sizes) {
  n <- sum(sizes)
  log_val <- lfactorial(n) - sum(lfactorial(sizes))
  round(exp(log_val))
}


#' All unique permutations of a vector
#'
#' Recursive enumeration. Intended only for small vectors; guard with an
#' upper threshold before calling.
#'
#' @param x character vector.
#' @return matrix whose rows are distinct permutations.
#' @keywords internal
#' @noRd
.unique_perms <- function(x) {
  if (length(x) <= 1L) return(matrix(x, nrow = 1L))
  result <- list(); used <- character(0)
  for (i in seq_along(x)) {
    if (x[i] %in% used) next
    used <- c(used, x[i])
    sub <- .unique_perms(x[-i])
    for (j in seq_len(nrow(sub)))
      result[[length(result) + 1L]] <- c(x[i], sub[j, ])
  }
  do.call(rbind, result)
}


#' Active node set for a given period
#'
#' A node is considered active in period `p` if it appears in the rownames
#' of `panel$matrices[[p]]`.
#'
#' @keywords internal
#' @noRd
.active_nodes <- function(panel, period) {
  rownames(panel$matrices[[period]])
}
