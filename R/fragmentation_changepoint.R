#' Piecewise linear regression with bootstrap confidence interval
#'
#' Fits a two-segment linear model with an unknown breakpoint to a
#' fragmentation ratio time series. The breakpoint is located by grid
#' search minimising residual sum of squares; a bootstrap confidence
#' interval is obtained by resampling the observation pairs.
#'
#' @param x Either a `fragmentation_ratio` object, or a data frame with
#'   columns `period` and `value` (in which case `value` is the smoothed
#'   or unsmoothed ratio).
#' @param value_column When `x` is a `fragmentation_ratio`, the column of
#'   `x$series` to fit. Default `"ratio_smoothed"`. Use `"ratio"` to fit
#'   the unsmoothed series.
#' @param min_edge_gap Integer, the number of periods at each end of the
#'   series excluded from candidate breakpoints. Default `5L`.
#' @param n_boot Integer, number of bootstrap replications for the
#'   breakpoint confidence interval. Default `1000L`.
#' @param seed Optional integer seed. Default `NULL`.
#'
#' @return An object of class `fragmentation_changepoint` with elements:
#' \describe{
#'   \item{breakpoint}{Estimated breakpoint period.}
#'   \item{ci}{Named numeric vector of length two: `lo` and `hi` (2.5th
#'     and 97.5th bootstrap percentiles).}
#'   \item{slope_before}{Pre-breakpoint slope (change in ratio per period).}
#'   \item{slope_after}{Post-breakpoint slope.}
#'   \item{p_before, p_after}{Two-sided p-values from the piecewise fit.}
#'   \item{r_squared}{Fit \eqn{R^2}.}
#'   \item{fitted}{Tibble with columns `period`, `observed`, `fitted`.}
#'   \item{config}{List of arguments used.}
#' }
#'
#' @details
#' The piecewise model is parameterised as
#' \deqn{y_t = \beta_0 + \beta_1 (t - bp) \cdot \mathbb{1}(t \leq bp) +
#'            \beta_2 (t - bp) \cdot \mathbb{1}(t > bp) + \varepsilon_t}
#' which produces a continuous fit with separate slopes either side of the
#' breakpoint. The breakpoint is chosen as the integer period in the
#' interior of the series that minimises the residual sum of squares.
#'
#' @examples
#' \donttest{
#' data(criminology_panel)
#' fr <- fragmentation_ratio(criminology_panel, normalise = "row")
#' cp <- fragmentation_changepoint(fr, seed = 42L)
#' print(cp)
#' plot(cp)
#' }
#'
#' @export
fragmentation_changepoint <- function(x,
                                      value_column = "ratio_smoothed",
                                      min_edge_gap = 5L,
                                      n_boot = 1000L,
                                      seed = NULL) {
  
  if (inherits(x, "fragmentation_ratio")) {
    s <- x$series
    periods <- suppressWarnings(as.numeric(s$period))
    if (all(is.na(periods)))
      stop("Cannot fit a changepoint when periods are not numeric. ",
           "Supply a data frame with a numeric `period` column.",
           call. = FALSE)
    vals <- s[[value_column]]
    ok <- !is.na(periods) & !is.na(vals)
    years <- periods[ok]; v <- vals[ok]
  } else if (is.data.frame(x)) {
    if (!all(c("period", "value") %in% names(x)))
      stop("Data frame must contain columns `period` and `value`.",
           call. = FALSE)
    years <- suppressWarnings(as.numeric(x$period))
    v <- x$value
    ok <- !is.na(years) & !is.na(v)
    years <- years[ok]; v <- v[ok]
  } else {
    stop("`x` must be a fragmentation_ratio object or a data frame.",
         call. = FALSE)
  }
  
  if (length(years) <= 2L * min_edge_gap + 1L)
    stop("Series is too short for a changepoint search at this `min_edge_gap`.",
         call. = FALSE)
  
  if (!is.null(seed)) set.seed(seed)
  
  bp_min <- min(years) + min_edge_gap
  bp_max <- max(years) - min_edge_gap
  
  best <- .search_bp(years, v, bp_min, bp_max)
  ci <- .bootstrap_bp(years, v, n_boot, bp_min, bp_max)
  fitted_vals <- .predict_pw(years, best)
  
  out <- list(
    breakpoint   = best$bp,
    ci           = c(lo = unname(ci[1L]), hi = unname(ci[2L])),
    slope_before = unname(best$beta[2L]),
    slope_after  = unname(best$beta[3L]),
    p_before     = unname(best$pvals[2L]),
    p_after      = unname(best$pvals[3L]),
    r_squared    = best$r2,
    fitted       = tibble::tibble(period = years,
                                  observed = v,
                                  fitted = fitted_vals),
    config       = list(value_column = value_column,
                        min_edge_gap = min_edge_gap,
                        n_boot = n_boot,
                        seed = seed,
                        call = sys.call())
  )
  class(out) <- c("fragmentation_changepoint", "citefrag_result")
  out
}


## ---- internal fitting helpers ---------------------------------------

#' @keywords internal
#' @noRd
.fit_pw <- function(years, vals, bp) {
  x <- as.numeric(years); y <- as.numeric(vals)
  x1 <- ifelse(x <= bp, x - bp, 0)
  x2 <- ifelse(x >  bp, x - bp, 0)
  X <- cbind(1, x1, x2)
  fit <- stats::lm.fit(X, y)
  beta <- fit$coefficients
  resid <- fit$residuals
  ss_res <- sum(resid^2)
  ss_tot <- sum((y - mean(y))^2)
  r2 <- 1 - ss_res / ss_tot
  n <- length(y); k <- 3L
  if (n - k > 0L && ss_res > 0) {
    sigma2 <- ss_res / (n - k)
    cov_mat <- sigma2 * solve(t(X) %*% X)
    se <- sqrt(diag(cov_mat))
    tvals <- beta / se
    pvals <- 2 * (1 - stats::pt(abs(tvals), n - k))
  } else {
    se <- rep(NA_real_, 3); pvals <- rep(NA_real_, 3)
  }
  list(beta = beta, se = se, pvals = pvals,
       r2 = r2, ss_res = ss_res, bp = bp)
}


#' @keywords internal
#' @noRd
.search_bp <- function(years, vals, bp_min, bp_max) {
  best <- NULL
  for (bp in bp_min:bp_max) {
    res <- tryCatch(.fit_pw(years, vals, bp), error = function(e) NULL)
    if (is.null(res)) next
    if (is.null(best) || res$ss_res < best$ss_res) best <- res
  }
  if (is.null(best))
    stop("No valid breakpoint found in the candidate range.",
         call. = FALSE)
  best
}


#' @keywords internal
#' @noRd
.bootstrap_bp <- function(years, vals, n_boot, bp_min, bp_max) {
  n <- length(years)
  bps <- integer(0)
  for (b in seq_len(n_boot)) {
    idx <- sample(n, n, replace = TRUE)
    ys <- years[idx]; vs <- vals[idx]
    o <- order(ys); ys <- ys[o]; vs <- vs[o]
    res <- tryCatch(.search_bp(ys, vs, bp_min, bp_max),
                    error = function(e) NULL)
    if (!is.null(res)) bps <- c(bps, res$bp)
  }
  if (length(bps) == 0L) return(c(NA_real_, NA_real_))
  stats::quantile(bps, c(0.025, 0.975))
}


#' @keywords internal
#' @noRd
.predict_pw <- function(years, best) {
  x <- as.numeric(years)
  x1 <- ifelse(x <= best$bp, x - best$bp, 0)
  x2 <- ifelse(x >  best$bp, x - best$bp, 0)
  best$beta[1L] + best$beta[2L] * x1 + best$beta[3L] * x2
}


## ---- methods --------------------------------------------------------

#' @export
print.fragmentation_changepoint <- function(x, ...) {
  cat("<fragmentation_changepoint>\n")
  cat(sprintf("  Breakpoint:   %s  (95%% bootstrap CI: %s to %s)\n",
              x$breakpoint,
              format(round(x$ci["lo"])),
              format(round(x$ci["hi"]))))
  cat(sprintf("  Slope before: %+.4f per period  (p = %s)\n",
              x$slope_before, format_p(x$p_before)))
  cat(sprintf("  Slope after:  %+.4f per period  (p = %s)\n",
              x$slope_after, format_p(x$p_after)))
  cat(sprintf("  R-squared:    %.3f\n", x$r_squared))
  invisible(x)
}


#' @export
summary.fragmentation_changepoint <- function(object, ...) {
  print(object)
  invisible(object)
}


#' @export
as.data.frame.fragmentation_changepoint <- function(x, ...) {
  as.data.frame(x$fitted)
}


#' @export
plot.fragmentation_changepoint <- function(x, ...) {
  f <- x$fitted
  ggplot2::ggplot(f, ggplot2::aes(x = .data$period)) +
    ggplot2::annotate("rect",
                      xmin = x$ci["lo"], xmax = x$ci["hi"],
                      ymin = -Inf, ymax = Inf,
                      fill = "grey85", alpha = 0.5) +
    ggplot2::geom_vline(xintercept = x$breakpoint,
                        linetype = "dashed", colour = "firebrick") +
    ggplot2::geom_point(ggplot2::aes(y = .data$observed),
                        colour = "grey40") +
    ggplot2::geom_line(ggplot2::aes(y = .data$fitted),
                       colour = "steelblue", linewidth = 1) +
    ggplot2::labs(
      x = "Period",
      y = "Ratio",
      title = sprintf("Piecewise fit, breakpoint = %s",
                      x$breakpoint),
      subtitle = sprintf("95%% bootstrap CI: %s to %s",
                         round(x$ci["lo"]), round(x$ci["hi"]))
    ) +
    ggplot2::theme_minimal(base_size = 12)
}
