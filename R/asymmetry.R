#' Directional asymmetry between two groups
#'
#' Measures how unevenly citations flow between two groups over time. For
#' each period, computes the mean share of within-set outgoing citations
#' that group `from_group` directs to group `to_group`, and the reverse,
#' and their ratio. A value far above one indicates that `from_group` is
#' much more attentive to `to_group` than vice versa.
#'
#' @param panel A `citation_panel` object.
#' @param from_group Character, a group label appearing in `panel$groups`.
#' @param to_group Character, a group label appearing in `panel$groups`.
#'   Must differ from `from_group`.
#' @param smooth Integer smoothing window. Default `3L`.
#'
#' @return An object of class `fragmentation_asymmetry` with elements:
#' \describe{
#'   \item{series}{Tibble with columns `period`, `n_from`, `n_to`,
#'     `from_to_share`, `to_from_share`, `asymmetry_ratio`, and
#'     `asymmetry_ratio_smoothed`.}
#'   \item{config}{List of arguments used.}
#'   \item{panel}{Input panel.}
#' }
#'
#' @examples
#' \donttest{
#' data(criminology_panel)
#' asy <- asymmetry(
#'   criminology_panel,
#'   from_group = "Critical/Theoretical",
#'   to_group   = "Quant/Empirical"
#' )
#' print(asy)
#' plot(asy)
#' }
#'
#' @export
asymmetry <- function(panel,
                      from_group,
                      to_group,
                      smooth = 3L) {
  
  stopifnot(inherits(panel, "citation_panel"))
  if (!from_group %in% panel$groups)
    stop(sprintf("'%s' is not a group label in this panel.", from_group),
         call. = FALSE)
  if (!to_group %in% panel$groups)
    stop(sprintf("'%s' is not a group label in this panel.", to_group),
         call. = FALSE)
  if (identical(from_group, to_group))
    stop("`from_group` and `to_group` must differ.", call. = FALSE)
  
  rows <- list()
  for (p in panel$periods) {
    active <- .active_nodes(panel, p)
    if (length(active) < 2L) next
    M <- panel$matrices[[p]][active, active, drop = FALSE]
    labs <- panel$groups[active]
    
    from_nodes <- active[labs == from_group]
    to_nodes   <- active[labs == to_group]
    
    ft_share <- .mean_directed_share(M, from_nodes, to_nodes)
    tf_share <- .mean_directed_share(M, to_nodes, from_nodes)
    asym <- if (!is.na(ft_share) && !is.na(tf_share) && tf_share > 0)
      ft_share / tf_share else NA_real_
    
    rows[[length(rows) + 1L]] <- data.frame(
      period          = p,
      n_from          = length(from_nodes),
      n_to            = length(to_nodes),
      from_to_share   = ft_share,
      to_from_share   = tf_share,
      asymmetry_ratio = asym,
      stringsAsFactors = FALSE
    )
  }
  
  series <- tibble::as_tibble(do.call(rbind, rows))
  series$asymmetry_ratio_smoothed <- if (smooth > 1L)
    .smooth3(series$asymmetry_ratio) else series$asymmetry_ratio
  
  out <- list(
    series = series,
    config = list(from_group = from_group,
                  to_group   = to_group,
                  smooth     = smooth,
                  call       = sys.call()),
    panel  = panel
  )
  class(out) <- c("fragmentation_asymmetry", "citefrag_result")
  out
}


#' Mean share of outgoing citations from a source set to a target set
#' 
#' For each source node, computes (citations to target set) / (total
#' outgoing citations within the active panel), then averages across source
#' nodes. Self-citations are excluded.
#' @keywords internal
#' @noRd
.mean_directed_share <- function(M, from_nodes, to_nodes) {
  if (length(from_nodes) == 0L || length(to_nodes) == 0L)
    return(NA_real_)
  active <- rownames(M)
  shares <- numeric(0L)
  for (fi in from_nodes) {
    outgoing <- M[fi, setdiff(active, fi)]
    total <- sum(outgoing)
    if (total == 0) next
    to_only <- setdiff(to_nodes, fi)
    to_total <- sum(M[fi, to_only])
    shares <- c(shares, to_total / total)
  }
  if (length(shares) == 0L) NA_real_ else mean(shares)
}


#' @export
print.fragmentation_asymmetry <- function(x, ...) {
  cat("<fragmentation_asymmetry>\n")
  cat(sprintf("  From group: %s\n", x$config$from_group))
  cat(sprintf("  To group:   %s\n", x$config$to_group))
  cat(sprintf("  Periods:    %d\n", nrow(x$series)))
  s <- x$series
  v <- s[!is.na(s$asymmetry_ratio), ]
  if (nrow(v) > 0L) {
    final <- v[nrow(v), ]
    cat(sprintf("  %s: ratio = %.2f (share %.3f vs %.3f)\n",
                final$period,
                final$asymmetry_ratio,
                final$from_to_share,
                final$to_from_share))
  }
  invisible(x)
}


#' @export
summary.fragmentation_asymmetry <- function(object, ...) {
  print(object)
  cat("\nFirst 10 rows of series:\n")
  print(utils::head(object$series, 10L))
  invisible(object)
}


#' @export
as.data.frame.fragmentation_asymmetry <- function(x, ...) {
  as.data.frame(x$series)
}


#' @export
plot.fragmentation_asymmetry <- function(x, ...) {
  s <- x$series
  s$period_num <- suppressWarnings(as.numeric(s$period))
  if (all(is.na(s$period_num))) s$period_num <- seq_len(nrow(s))
  
  ggplot2::ggplot(s, ggplot2::aes(x = .data$period_num)) +
    ggplot2::geom_hline(yintercept = 1, linetype = "dashed",
                        colour = "grey50") +
    ggplot2::geom_line(ggplot2::aes(y = .data$asymmetry_ratio_smoothed),
                       linewidth = 1, colour = "darkorange") +
    ggplot2::geom_point(ggplot2::aes(y = .data$asymmetry_ratio),
                        alpha = 0.5, colour = "darkorange") +
    ggplot2::labs(
      x = "Period",
      y = sprintf("Asymmetry ratio (%s to %s)",
                  x$config$from_group, x$config$to_group),
      title = "Directional asymmetry"
    ) +
    ggplot2::theme_minimal(base_size = 12)
}
