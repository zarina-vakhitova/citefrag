test_that("citation_panel validates basic inputs", {
  M <- matrix(1, 3, 3, dimnames = list(c("a","b","c"), c("a","b","c")))
  mats <- list("2020" = M)
  groups <- c(a = "X", b = "X", c = "Y")
  
  p <- citation_panel(mats, groups)
  expect_s3_class(p, "citation_panel")
  expect_equal(p$n_periods, 1L)
  expect_equal(p$n_nodes, 3L)
  expect_equal(p$n_groups, 2L)
})

test_that("citation_panel rejects unnamed matrices", {
  M <- matrix(1, 2, 2, dimnames = list(c("a","b"), c("a","b")))
  expect_error(citation_panel(list(M), c(a = "X", b = "Y")),
               "must be named")
})

test_that("citation_panel rejects missing nodes in groups", {
  M <- matrix(1, 2, 2, dimnames = list(c("a","b"), c("a","b")))
  expect_error(citation_panel(list("2020" = M), c(a = "X")),
               "Nodes missing")
})

test_that("citation_panel rejects non-square matrices", {
  M <- matrix(1, 2, 3, dimnames = list(c("a","b"), c("a","b","c")))
  expect_error(
    citation_panel(list("2020" = M), c(a = "X", b = "X", c = "Y")),
    "not square"
  )
})
