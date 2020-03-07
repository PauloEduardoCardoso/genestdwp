test_that(context("Object size"), {
  dist = c(10, 20, 30, 40, 50)
  rings <- viring(x = visib, d = dist)
  df <- dwp(vr = rings, pt = pto_carcass)
  # df
  expect_equal(dim(df), c(37, 2))
})
