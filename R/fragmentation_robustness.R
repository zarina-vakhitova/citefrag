#' Robustness checks for the fragmentation ratio
#'
#' Recomputes the ratio series under alternative group specifications or
#' restricted node subsets, and compares each alternative to the baseline.
#' This is the function that answers "does the trajectory depend on my
#' specific cluster assignment?" and "does it depend on which nodes I
#' include?".
#'
#' @param panel A `citation_panel` object, representing the baseline
#'   specification.
#' @param alternatives Optional named list of alternative group vectors.
#'   Each element must be a named character vector with the same node
#'   identifiers as `panel$groups`, but possibly with different group
#'   labels. For example,
#'   `list(merge_A_B = c(j1 = "X", j2 = "X", j3 = "Y"))`.
#' @param subpanels Optional named list of node subsets. Each element is a
#'   character vector of node identifiers to retain. The ratio is
#'   recomputed on each subpanel using only those nodes.
#' @param normalise Character, as in [fragmentation_ratio()]. Default
#'   `"raw"`.
#' @param smooth Integer smoothing window. Default `3L`.
#'
#' @return An object of class `fragmentation_robustness` with elements:
#' \describe{
#'   \item{series}{Tibble with columns `specification`, `period`, `ratio`,
#'     and `ratio_smoothed`, long-form across all specifications
#'     (baseline plus alternatives plus subpanels).}
#'   \item{correlations}{Tibble with one row per non-baseline specification,
#'     columns `specification`, `r_raw`, `r_smooth`: the correlation with
#'     the baseline ratio and with the smoothed baseline ratio.}
#'   \item{config}{List of arguments used.}
#'   \item{panel}{Input panel.}
#' }
#'
#' @examples
#' \donttest{
#' data(criminology_panel)
#' # Alternative specification: merge two groups into one
#' g0 <- criminology_panel$groups
#' alt <- g0; alt[alt == "Intl/Comparative"] <- "Critical/Theoretical"
#' rb <- fragmentation_robustness(
#'   criminology_panel,
#'   alternatives = list(merged_crit_intl = alt)
#' )
#' print(rb)
#' plot(rb)
#' }
#'
#' @seealso [fragmentation_ratio()].
#' @export
fragmentation_robustness <- function(panel,
                                     alternatives = NULL,
                                     subpanels = NULL,
                                     normalise = c("raw", "row", "target",
                                                   "article_pair"),
                                     smooth = 3L) {
  
  stopifnot(inherits(panel, "citation_panel"))
  normalise <- match.arg(normalise)
  
  # Baseline
  baseline <- fragmentation_ratio(panel, normalise = normalise,
                                  smooth = smooth)
  base_series <- baseline$series
  base_series$specification <- "baseline"
  
  all_series <- list(base_series)
  cor_rows <- list()
  
  # Alternative group vectors
  if (!is.null(alternatives)) {
    if (is.null(names(alternatives)) || any(names(alternatives) == ""))
      stop("`alternatives` must be a named list.", call. = FALSE)
    for (nm in names(alternatives)) {
      alt_panel <- panel
      alt_panel$groups <- alternatives[[nm]]
      alt_panel$n_groups <- length(unique(alt_panel$groups))
      res <- fragmentation_ratio(alt_panel, normalise = normalise,
                                 smooth = smooth)
      res$series$specification <- nm
      all_series[[length(all_series) + 1L]] <- res$series
      cor_rows[[length(cor_rows) + 1L]] <-
        .compute_correlations(base_series, res$series, nm)
    }
  }
  
  # Subpanels (fixed-panel robustness)
  if (!is.null(subpanels)) {
    if (is.null(names(subpanels)) || any(names(subpanels) == ""))
      stop("`subpanels` must be a named list.", call. = FALSE)
    for (nm in names(subpanels)) {
      keep <- subpanels[[nm]]
      missing <- setdiff(keep, panel$nodes)
      if (length(missing) > 0L)
        stop(sprintf("subpanels[['%s']] contains unknown nodes: %s",
                     nm, paste(missing, collapse = ", ")),
             call. = FALSE)
      sub_matrices <- lapply(panel$matrices, function(M) {
        active <- intersect(keep, rownames(M))
        if (length(active) < 2L) return(NULL)
        M[active, active, drop = FALSE]
      })
      sub_matrices <- sub_matrices[!vapply(sub_matrices, is.null, logical(1L))]
      if (length(sub_matrices) == 0L) next
      sub_panel <- citation_panel(
        matrices = sub_matrices,
        groups   = panel$groups[keep],
        sizes    = if (!is.null(panel$sizes)) panel$sizes else NULL
      )
      res <- fragmentation_ratio(sub_panel, normalise = normalise,
                                 smooth = smooth)
      res$series$specification <- nm
      all_series[[length(all_series) + 1L]] <- res$series
      cor_rows[[length(cor_rows) + 1L]] <-
        .compute_correlations(base_series, res$series, nm)
    }
  }
  
  series <- tibble::as_tibble(do.call(rbind, all_series))
  series <- series[, c("specification", "period", "n_nodes",
                       "ratio", "ratio_smoothed")]
  correlations <- if (length(cor_rows) > 0L)
    tibble::as_tibble(do.call(rbind, cor_rows))
  else
    tibble::tibble(specification = character(0),
                   r_raw = double(0),
                   r_smooth = double(0))
  
  out <- list(
    series       = series,
    correlations = correlations,
    config       = list(normalise = normalise, smooth = smooth,
                        call = sys.call()),
    panel        = panel
  )
  class(out) <- c("fragmentation_robustness", "citefrag_result")
  out
}


#' @keywords internal
#' @noRd
.compute_correlations <- function(base, alt, name) {
  m <- merge(base[, c("period", "ratio", "ratio_smoothed")],
             alt[, c("period", "ratio", "ratio_smoothed")],
             by = "period", suffixes = c("_base", "_alt"))
  m <- m[stats::complete.cases(m), , drop = FALSE]
  r_raw <- if (nrow(m) > 2L) stats::cor(m$ratio_base, m$ratio_alt)
           else NA_real_
  r_sm  <- if (nrow(m) > 2L)
    stats::cor(m$ratio_smoothed_base, m$ratio_smoothed_alt)
           else NA_real_
  data.frame(specification = name,
             r_raw = r_raw,
             r_smooth = r_sm,
             stringsAsFactors = FALSE)
}


#' @export
print.fragmentation_robustness <- function(x, ...) {
  cat("<fragmentation_robustness>\n")
  cat(sprintf("  Normalisation: %s\n", x$config$normalise))
  cat(sprintf("  Specifications: %d (including baseline)\n",
              length(unique(x$series$specification))))
  if (nrow(x$correlations) > 0L) {
    cat("\n  Correlations with baseline:\n")
    for (i in seq_len(nrow(x$correlations))) {
      cat(sprintf("    %-25s  r = %.3f (raw), %.3f (smoothed)\n",
                  x$correlations$specification[i],
                  x$correlations$r_raw[i],
                  x$correlations$r_smooth[i]))
    }
  }
  invisible(x)
}


#' @export
summary.fragmentation_robustness <- function(object, ...) {
  print(object)
  invisible(object)
}


#' @export
as.data.frame.fragmentation_robustness <- function(x, ...) {
  as.data.frame(x$series)
}


#' @export
plot.fragmentation_robustness <- function(x, ...) {
  s <- x$series
  s$period_num <- suppressWarnings(as.numeric(s$period))
  if (all(is.na(s$period_num))) s$period_num <- seq_len(nrow(s))
  
  ggplot2::ggplot(s, ggplot2::aes(x = .data$period_num,
                                  y = .data$ratio_smoothed,
                                  colour = .data$specification)) +
    ggplot2::geom_hline(yintercept = 1, linetype = "dashed",
                        colour = "grey50") +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::labs(
      x = "Period",
      y = "Within/between citation ratio (smoothed)",
      title = "Ratio trajectory under alternative specifications",
      colour = "Specification"
    ) +
    ggplot2::theme_minimal(base_size = 12)
}
