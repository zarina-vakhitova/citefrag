#' Permutation test for the fragmentation ratio
#'
#' Tests whether the observed within-between ratio exceeds what would be
#' obtained under random assignment of nodes to groups of the same sizes.
#' For small label sets (where the number of distinct permutations is at
#' or below `exact_threshold`) the test is exact; otherwise it is
#' approximated by Monte Carlo sampling.
#'
#' @param panel A `citation_panel` object.
#' @param n_perm Integer, number of Monte Carlo permutations when exact
#'   enumeration is infeasible. Default `10000L`.
#' @param exact_threshold Integer. If the number of distinct permutations of
#'   the group labels is at or below this value, the test is carried out by
#'   exact enumeration rather than Monte Carlo. Default `1000L`.
#' @param normalise Character, one of `"raw"`, `"row"`, `"target"`,
#'   `"article_pair"`. Default `"raw"`.
#' @param seed Optional integer seed for reproducibility of the Monte Carlo
#'   sampling. Default `NULL`.
#'
#' @return An object of class `fragmentation_test` (inheriting from
#'   `citefrag_result`), a list with elements:
#' \describe{
#'   \item{results}{Tibble with one row per period: `period`, `n_nodes`,
#'     `observed`, `null_mean`, `null_sd`, `null_q05`, `null_q95`,
#'     `null_q99`, `z`, `p_value`, `method` ("exact" or "monte_carlo"),
#'     and `n_distinct_perms`.}
#'   \item{config}{List of arguments used.}
#'   \item{panel}{Input panel.}
#' }
#'
#' @details
#' The null hypothesis is that the observed pattern of within-group
#' preference could be produced by chance, given the fixed group sizes and
#' the observed citation matrix. The test holds the group sizes and the
#' citation matrix fixed and permutes the mapping from nodes to group
#' labels; for each permutation, the ratio is recomputed. The z-score is
#' \eqn{(R_{obs} - \bar{R}_{null}) / \mathrm{sd}(R_{null})}; the p-value is
#' the proportion of null ratios at least as extreme as the observed.
#'
#' Periods with fewer than four active nodes, or with fewer than two groups
#' of size at least two, are skipped.
#'
#' @examples
#' \donttest{
#' data(criminology_panel)
#' pt <- fragmentation_test(criminology_panel, n_perm = 1000L, seed = 42L)
#' print(pt)
#' }
#'
#' @seealso [fragmentation_ratio()], [fragmentation_robustness()].
#' @export
fragmentation_test <- function(panel,
                               n_perm = 10000L,
                               exact_threshold = 1000L,
                               normalise = c("raw", "row", "target", "article_pair"),
                               seed = NULL) {
  
  stopifnot(inherits(panel, "citation_panel"))
  normalise <- match.arg(normalise)
  n_perm <- as.integer(n_perm)
  exact_threshold <- as.integer(exact_threshold)
  
  if (!is.null(seed)) set.seed(seed)
  
  results <- list()
  for (p in panel$periods) {
    active <- .active_nodes(panel, p)
    na <- length(active)
    if (na < 4L) next
    
    labels_true <- panel$groups[active]
    csz <- table(labels_true)
    if (sum(csz >= 2L) < 2L) next
    
    M <- panel$matrices[[p]][active, active, drop = FALSE]
    sizes_p <- .sizes_for_period(panel, p, active)
    M_norm <- .normalise_matrix(M, normalise, sizes_p)
    
    obs <- .ratio_core(M_norm, labels_true)
    if (is.na(obs)) next
    
    sizes_int <- as.integer(table(labels_true))
    n_distinct <- .multinomial_count(sizes_int)
    
    if (n_distinct <= exact_threshold) {
      all_p <- .unique_perms(labels_true)
      null_dist <- apply(all_p, 1L, function(lab) .ratio_core(M_norm, lab))
      method <- "exact"
    } else {
      null_dist <- replicate(n_perm,
                             .ratio_core(M_norm, sample(labels_true)))
      method <- "monte_carlo"
    }
    null_dist <- null_dist[!is.na(null_dist)]
    if (length(null_dist) == 0L) next
    
    nm <- mean(null_dist); nsd <- stats::sd(null_dist)
    z <- if (nsd > 0) (obs - nm) / nsd else NA_real_
    pv <- mean(null_dist >= obs)
    
    results[[length(results) + 1L]] <- data.frame(
      period           = p,
      n_nodes          = na,
      observed         = obs,
      null_mean        = nm,
      null_sd          = nsd,
      null_q05         = unname(stats::quantile(null_dist, 0.05)),
      null_q95         = unname(stats::quantile(null_dist, 0.95)),
      null_q99         = unname(stats::quantile(null_dist, 0.99)),
      z                = z,
      p_value          = pv,
      method           = method,
      n_distinct_perms = n_distinct,
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  }
  
  tbl <- tibble::as_tibble(do.call(rbind, results))
  
  out <- list(
    results = tbl,
    config  = list(normalise = normalise, n_perm = n_perm,
                   exact_threshold = exact_threshold,
                   seed = seed, call = sys.call()),
    panel   = panel
  )
  class(out) <- c("fragmentation_test", "citefrag_result")
  out
}


#' @export
print.fragmentation_test <- function(x, ...) {
  r <- x$results
  cat("<fragmentation_test>\n")
  cat(sprintf("  Normalisation: %s\n", x$config$normalise))
  cat(sprintf("  Periods tested: %d\n", nrow(r)))
  if (nrow(r) > 0L) {
    final <- r[nrow(r), ]
    cat(sprintf("  %s: observed R = %.2f, null mean = %.2f, z = %.2f, p = %s\n",
                final$period, final$observed, final$null_mean, final$z,
                format_p(final$p_value)))
  }
  invisible(x)
}


#' @export
summary.fragmentation_test <- function(object, ...) {
  print(object)
  cat("\nFirst 10 rows of results:\n")
  print(utils::head(object$results, 10L))
  invisible(object)
}


#' @export
as.data.frame.fragmentation_test <- function(x, ...) {
  as.data.frame(x$results)
}


#' @export
plot.fragmentation_test <- function(x, ...) {
  r <- x$results
  r$period_num <- suppressWarnings(as.numeric(r$period))
  if (all(is.na(r$period_num))) r$period_num <- seq_len(nrow(r))
  
  ggplot2::ggplot(r, ggplot2::aes(x = .data$period_num)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$null_q05,
                                      ymax = .data$null_q95),
                         fill = "grey80", alpha = 0.6) +
    ggplot2::geom_line(ggplot2::aes(y = .data$null_mean),
                       colour = "grey40", linetype = "dashed") +
    ggplot2::geom_line(ggplot2::aes(y = .data$observed),
                       linewidth = 1, colour = "steelblue") +
    ggplot2::geom_point(ggplot2::aes(y = .data$observed),
                        colour = "steelblue") +
    ggplot2::labs(
      x = "Period",
      y = "Ratio R",
      title = "Observed ratio versus permutation null envelope",
      subtitle = "Shaded band = 5th-95th percentile of null distribution"
    ) +
    ggplot2::theme_minimal(base_size = 12)
}


# Small helper for printing p-values
format_p <- function(p) {
  if (is.na(p)) return("NA")
  if (p < 0.0001) "< 0.0001" else sprintf("%.4f", p)
}
