#' Compute the fragmentation ratio time series
#'
#' The central measurement function of the package. For each period in the
#' panel, computes the pair-averaged within-group to between-group citation
#' ratio under the requested normalisation, and returns the ratio series
#' alongside supporting counts and an optional smoothed trajectory.
#'
#' @param panel A `citation_panel` object from [citation_panel()].
#' @param normalise Character, one of `"raw"`, `"row"`, `"target"`, or
#'   `"article_pair"`. Default `"raw"`. See Details.
#' @param smooth Integer window length for centred moving-average smoothing
#'   of the ratio. Default `3L`. Set to `1L` to disable smoothing.
#'
#' @return An object of class `fragmentation_ratio` (inheriting from
#'   `citefrag_result`), which is a list with elements:
#' \describe{
#'   \item{series}{A tibble with one row per period and columns `period`,
#'     `n_nodes`, `within_mean`, `between_mean`, `ratio`, and
#'     `ratio_smoothed`.}
#'   \item{config}{List recording `normalise`, `smooth`, and the call.}
#'   \item{panel}{The input panel, for downstream use.}
#' }
#'
#' @details
#' **Normalisations.** The `"raw"` option uses the citation counts as
#' supplied. `"row"` divides each row of each matrix by its row sum before
#' aggregation, so that every citing node contributes equally regardless of
#' its publication volume. `"target"` additionally divides each cell by the
#' size (for example, article count) of the cited node, controlling for
#' differences in the size of citation targets. `"article_pair"` uses
#' \eqn{\Omega_{ij} = C_{ij} / (n_i \cdot n_j)} directly, removing size
#' effects on both sides simultaneously. The latter two require `sizes` to
#' have been supplied when the panel was constructed.
#'
#' **Smoothing.** The `ratio_smoothed` column is a centred moving average
#' computed in the observation domain, not a time-series filter; it is a
#' cosmetic aid for plotting rather than a statistical operation. All
#' significance testing uses the unsmoothed ratio.
#'
#' @examples
#' \dontrun{
#' data(criminology_panel)
#' fr <- fragmentation_ratio(criminology_panel, normalise = "row")
#' print(fr)
#' plot(fr)
#' }
#'
#' @seealso [fragmentation_test()] for significance testing,
#'   [fragmentation_changepoint()] for structural break detection.
#' @export
fragmentation_ratio <- function(panel,
                                normalise = c("raw", "row", "target", "article_pair"),
                                smooth = 3L) {
  
  stopifnot(inherits(panel, "citation_panel"))
  normalise <- match.arg(normalise)
  smooth <- as.integer(smooth)
  if (smooth < 1L) stop("`smooth` must be a positive integer.", call. = FALSE)
  
  rows <- list()
  for (p in panel$periods) {
    active <- .active_nodes(panel, p)
    if (length(active) < 2L) next
    
    M <- panel$matrices[[p]][active, active, drop = FALSE]
    sizes_p <- .sizes_for_period(panel, p, active)
    M_norm <- .normalise_matrix(M, normalise, sizes_p)
    
    labels <- panel$groups[active]
    
    # Need at least two groups of two for the ratio to be defined
    csz <- table(labels)
    if (sum(csz >= 2L) < 2L) next
    
    n <- length(labels)
    same <- outer(labels, labels, "==")
    diag_mask <- diag(TRUE, n)
    wmask <- same & !diag_mask
    bmask <- !same & !diag_mask
    wp <- sum(wmask); bp <- sum(bmask)
    wc <- sum(M_norm[wmask]); bc <- sum(M_norm[bmask])
    aw <- wc / max(wp, 1L); ab <- bc / max(bp, 1L)
    
    rows[[length(rows) + 1L]] <- data.frame(
      period       = p,
      n_nodes      = length(active),
      within_mean  = aw,
      between_mean = ab,
      ratio        = if (bp > 0L) aw / max(ab, 1e-10) else NA_real_,
      stringsAsFactors = FALSE
    )
  }
  
  series <- do.call(rbind, rows)
  series$ratio_smoothed <- if (smooth > 1L) .smooth3(series$ratio) else series$ratio
  series <- tibble::as_tibble(series)
  
  out <- list(
    series = series,
    config = list(normalise = normalise, smooth = smooth, call = sys.call()),
    panel  = panel
  )
  class(out) <- c("fragmentation_ratio", "citefrag_result")
  out
}


#' @export
print.fragmentation_ratio <- function(x, ...) {
  s <- x$series
  v <- s[!is.na(s$ratio), ]
  cat("<fragmentation_ratio>\n")
  cat(sprintf("  Periods: %d  (%s to %s)\n",
              nrow(s), s$period[1L], s$period[nrow(s)]))
  cat(sprintf("  Normalisation: %s\n", x$config$normalise))
  cat(sprintf("  Smoothing:     %d-period centred moving average\n",
              x$config$smooth))
  if (nrow(v) > 0L) {
    pk <- v[which.max(v$ratio), ]
    cat(sprintf("  Peak:   R = %.2f  in %s\n", pk$ratio, pk$period))
    fin <- v[nrow(v), ]
    cat(sprintf("  Final:  R = %.2f  in %s\n", fin$ratio, fin$period))
  }
  invisible(x)
}


#' @export
summary.fragmentation_ratio <- function(object, ...) {
  print(object)
  cat("\nFirst 10 rows of series:\n")
  print(utils::head(object$series, 10L))
  invisible(object)
}


#' @export
as.data.frame.fragmentation_ratio <- function(x, ...) {
  as.data.frame(x$series)
}


#' @export
plot.fragmentation_ratio <- function(x, ...) {
  s <- x$series
  s$period_num <- suppressWarnings(as.numeric(s$period))
  # Fall back to row index if period identifiers are not numeric
  if (all(is.na(s$period_num))) s$period_num <- seq_len(nrow(s))
  
  ggplot2::ggplot(s, ggplot2::aes(x = .data$period_num)) +
    ggplot2::geom_hline(yintercept = 1, linetype = "dashed",
                        colour = "grey50") +
    ggplot2::geom_point(ggplot2::aes(y = .data$ratio), alpha = 0.5) +
    ggplot2::geom_line(ggplot2::aes(y = .data$ratio_smoothed),
                       linewidth = 1) +
    ggplot2::labs(
      x = "Period",
      y = "Within/between citation ratio",
      title = sprintf("Fragmentation ratio (%s)", x$config$normalise)
    ) +
    ggplot2::theme_minimal(base_size = 12)
}
