#' Run the full fragmentation analysis pipeline
#'
#' Convenience wrapper that runs [fragmentation_ratio()],
#' [fragmentation_test()], [fragmentation_robustness()], and
#' [fragmentation_changepoint()] in sequence, returning a list of the four
#' result objects. Useful for reproducing a complete analysis in a single
#' call, for example in a replication vignette.
#'
#' @param panel A `citation_panel` object.
#' @param normalise Character, as in [fragmentation_ratio()]. Default
#'   `"raw"`.
#' @param smooth Integer smoothing window. Default `3L`.
#' @param n_perm Integer, number of Monte Carlo permutations. Default
#'   `10000L`.
#' @param alternatives Optional named list of alternative group vectors.
#'   Default `NULL`, in which case no robustness check against alternative
#'   groupings is carried out.
#' @param subpanels Optional named list of node subsets. Default `NULL`.
#' @param seed Optional integer seed. Default `NULL`.
#' @param verbose Logical, print progress messages. Default `TRUE`.
#'
#' @return A named list with elements `ratio`, `test`, `robustness`, and
#'   `changepoint`. `robustness` is `NULL` when neither `alternatives` nor
#'   `subpanels` are supplied.
#'
#' @examples
#' \donttest{
#' data(criminology_panel)
#' res <- fragmentation_analysis(criminology_panel, seed = 42L)
#' plot(res$ratio)
#' plot(res$changepoint)
#' }
#'
#' @export
fragmentation_analysis <- function(panel,
                                   normalise = c("raw", "row", "target",
                                                 "article_pair"),
                                   smooth = 3L,
                                   n_perm = 10000L,
                                   alternatives = NULL,
                                   subpanels = NULL,
                                   seed = NULL,
                                   verbose = TRUE) {
  
  normalise <- match.arg(normalise)
  msg <- function(x) if (verbose) message(x)
  
  msg("[1/4] Computing fragmentation ratio...")
  ratio <- fragmentation_ratio(panel, normalise = normalise,
                               smooth = smooth)
  
  msg("[2/4] Running permutation test...")
  test <- fragmentation_test(panel, n_perm = n_perm,
                             normalise = normalise, seed = seed)
  
  rob <- NULL
  if (!is.null(alternatives) || !is.null(subpanels)) {
    msg("[3/4] Running robustness checks...")
    rob <- fragmentation_robustness(panel,
                                    alternatives = alternatives,
                                    subpanels    = subpanels,
                                    normalise    = normalise,
                                    smooth       = smooth)
  } else {
    msg("[3/4] Skipping robustness checks (none requested).")
  }
  
  msg("[4/4] Fitting changepoint...")
  cp <- tryCatch(
    fragmentation_changepoint(ratio, seed = seed),
    error = function(e) {
      msg(sprintf("  Changepoint fit failed: %s", conditionMessage(e)))
      NULL
    }
  )
  
  list(
    ratio       = ratio,
    test        = test,
    robustness  = rob,
    changepoint = cp
  )
}
