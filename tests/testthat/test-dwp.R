test_that(context("Object size from dwp"), {
  # fail to resolve object dimension
  library(genestdwp)
  library(sf)
  library(tidyverse)
  dist = c(10, 20, 30, 40, 50)
  rings <- viring(x=visib, d = dist)
  df <- dwp(vr = rings, pt = pto_carcass)
  expect_equal(dim(df), c(37, 2))
  expect_warning(nrow(filter(cr, visib == 0)) != 0)
})
