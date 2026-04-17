test_that("fragmentation_changepoint recovers a planted break", {
  set.seed(1)
  # Series that rises then falls at year 2000
  years <- 1970:2025
  bp_true <- 2000
  vals <- ifelse(years <= bp_true,
                 0.05 * (years - bp_true),
                 -0.03 * (years - bp_true)) +
          stats::rnorm(length(years), sd = 0.1)
  
  df <- data.frame(period = years, value = vals)
  cp <- fragmentation_changepoint(df, seed = 1L, n_boot = 200L)
  
  expect_s3_class(cp, "fragmentation_changepoint")
  expect_true(abs(cp$breakpoint - bp_true) <= 5L)
  expect_gt(cp$slope_before, 0)
  expect_lt(cp$slope_after, 0)
})


test_that("fragmentation_changepoint accepts a ratio object", {
  # Build a trivial panel so we have a fragmentation_ratio to pass in
  years <- as.character(1970:2025)
  matrices <- lapply(years, function(y) {
    # noisy within-preferring matrix, with the preference declining over time
    t <- as.numeric(y) - 1970
    strength <- 10 - 0.1 * t
    M <- matrix(c(0, strength, 1, 1,
                  strength, 0, 1, 1,
                  1, 1, 0, strength,
                  1, 1, strength, 0),
                nrow = 4, byrow = TRUE,
                dimnames = list(c("a","b","c","d"), c("a","b","c","d")))
    M
  })
  names(matrices) <- years
  panel <- citation_panel(matrices,
                          groups = c(a = "X", b = "X", c = "Y", d = "Y"))
  fr <- fragmentation_ratio(panel, normalise = "raw", smooth = 3L)
  cp <- fragmentation_changepoint(fr, seed = 1L, n_boot = 100L)
  
  expect_s3_class(cp, "fragmentation_changepoint")
  expect_true(!is.na(cp$breakpoint))
})
