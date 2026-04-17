test_that("fragmentation_ratio returns correct structure", {
  M <- matrix(c(0, 5, 1, 1,
                5, 0, 1, 1,
                1, 1, 0, 5,
                1, 1, 5, 0),
              nrow = 4, byrow = TRUE,
              dimnames = list(c("a","b","c","d"), c("a","b","c","d")))
  panel <- citation_panel(
    matrices = list("2020" = M),
    groups   = c(a = "X", b = "X", c = "Y", d = "Y")
  )
  fr <- fragmentation_ratio(panel, normalise = "raw", smooth = 1L)
  
  expect_s3_class(fr, "fragmentation_ratio")
  expect_true("ratio" %in% names(fr$series))
  expect_equal(nrow(fr$series), 1L)
})

test_that("fragmentation_ratio gives R = 5 on perfectly segregated toy", {
  # Within-group cells = 5, between-group cells = 1. 
  # With 2 within pairs and 8 between pairs, pair-averaged ratio = 
  # (10/2) / (8/8) = 5 / 1 = 5.
  M <- matrix(c(0, 5, 1, 1,
                5, 0, 1, 1,
                1, 1, 0, 5,
                1, 1, 5, 0),
              nrow = 4, byrow = TRUE,
              dimnames = list(c("a","b","c","d"), c("a","b","c","d")))
  panel <- citation_panel(
    matrices = list("2020" = M),
    groups   = c(a = "X", b = "X", c = "Y", d = "Y")
  )
  fr <- fragmentation_ratio(panel, normalise = "raw", smooth = 1L)
  expect_equal(fr$series$ratio[1L], 5, tolerance = 1e-8)
})

test_that("fragmentation_ratio gives R = 1 on uniform toy", {
  M <- matrix(1, 4, 4, 
              dimnames = list(c("a","b","c","d"), c("a","b","c","d")))
  diag(M) <- 0
  panel <- citation_panel(
    matrices = list("2020" = M),
    groups   = c(a = "X", b = "X", c = "Y", d = "Y")
  )
  fr <- fragmentation_ratio(panel, normalise = "raw", smooth = 1L)
  expect_equal(fr$series$ratio[1L], 1, tolerance = 1e-8)
})
