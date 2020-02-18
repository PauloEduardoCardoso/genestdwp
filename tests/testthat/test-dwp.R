rings <- viring(x=visib, d = dist)
test_that(context("Object size from dwp"), {
  library(genestdwp)
  library(sf)
  library(tidyverse)
  dist = c(10, 20, 30, 40, 50)
  df <- dwp(vr = rings, pt = pto_carcass)
  expect_equal(dim(df), c(37, 2))
})
