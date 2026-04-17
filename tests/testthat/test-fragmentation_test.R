test_that("fragmentation_test rejects null on a clearly segregated matrix", {
  # Six nodes in two groups of three: 20 distinct permutations,
  # minimum achievable p-value is 2/20 = 0.1.
  mk <- function(w, b) {
    M <- matrix(b, 6, 6,
                dimnames = list(letters[1:6], letters[1:6]))
    # Group 1: a,b,c. Group 2: d,e,f.
    g1 <- 1:3; g2 <- 4:6
    M[g1, g1] <- w; M[g2, g2] <- w
    diag(M) <- 0
    M
  }
  M <- mk(w = 10, b = 1)
  panel <- citation_panel(
    matrices = list("2020" = M),
    groups   = setNames(c(rep("X", 3), rep("Y", 3)), letters[1:6])
  )
  pt <- fragmentation_test(panel, exact_threshold = 100L, seed = 1L)
  
  expect_s3_class(pt, "fragmentation_test")
  expect_true(nrow(pt$results) >= 1L)
  expect_lt(pt$results$p_value[1L], 0.2)
  expect_gt(pt$results$observed[1L], pt$results$null_mean[1L])
})


test_that("fragmentation_test uses exact enumeration when feasible", {
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
  pt <- fragmentation_test(panel, exact_threshold = 1000L, seed = 1L)
  expect_equal(pt$results$method[1L], "exact")
})


test_that("fragmentation_test does not reject on a uniform matrix", {
  M <- matrix(5, 4, 4,
              dimnames = list(c("a","b","c","d"), c("a","b","c","d")))
  diag(M) <- 0
  panel <- citation_panel(
    matrices = list("2020" = M),
    groups   = c(a = "X", b = "X", c = "Y", d = "Y")
  )
  pt <- fragmentation_test(panel, exact_threshold = 100L, seed = 1L)
  expect_equal(pt$results$observed[1L], 1, tolerance = 1e-8)
})
