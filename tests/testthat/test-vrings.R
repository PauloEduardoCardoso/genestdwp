test_that(context("Object size from vrings"), {
  # fail to resolve object dimension
  library(genestdwp)
  library(sf)
  library(tidyverse)
  dist = c(10, 20, 30, 40, 50)
  rings <- viring(x=visib, d = dist)
  expect_equal(dim(rings), c(1965, 7))
})
