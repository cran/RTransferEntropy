# construct two time-series
set.seed(1234567890)
n <- 1000
x <- rep(0, n + 1)
y <- rep(0, n + 1)
for (i in seq(n)) {
  x[i + 1] <- 0.2 * x[i] + rnorm(1, 0, 2)
  y[i + 1] <- x[i] + rnorm(1, 0, 2)
}
x <- x[-1]
y <- y[-1]

#################################
# Shannon Entropy
#################################

context("Shannon's Entropy")

test_that("transfer_entropy shannon is correctly specified", {
  # calc_te X->Y
  res <- calc_te(x, y)
  expect_type(res, "double")
  expect_length(res, 1)
  expect_equal(res, 0.1120278, tolerance = 1e-6)

  # calc_te Y->X
  res <- calc_te(y, x)
  expect_type(res, "double")
  expect_length(res, 1)
  expect_equal(res, 0.007642886, tolerance = 1e-6)

  # calc_ete X->Y
  res <- calc_ete(x, y, seed = 1234567890)
  expect_type(res, "double")
  expect_length(res, 1)
  expect_equal(res, 0.1052938, tolerance = 1e-6)

  # calc_ete Y->X
  res <- calc_ete(y, x, seed = 1234567890)
  expect_type(res, "double")
  expect_length(res, 1)
  expect_equal(res, 0.001819, tolerance = 1e-6)

  # transfer_entropy
  suppressWarnings({
    res <- transfer_entropy(x, y,
      lx = 1, ly = 1, nboot = 10, quiet = T,
      seed = 12345667
    )
  })

  # check types
  expect_true(is.transfer_entropy(res))

  # we have the all observations saved properly
  expect_equal(res$entropy, "shannon")
  expect_equal(res$obs$x, x)
  expect_equal(res$obs$y, y)
  expect_equal(res$nobs, n)

  # check the coefficients
  coefs <- coef(res)
  expect_true(is.matrix(coefs))
  expect_equal(dim(coefs), c(2, 4))

  # check bootstrapped results
  boot <- res$boot
  expect_true(is.matrix(boot))
  expect_equal(dim(boot), c(2, 10))

  # check values
  exp_coefs <- matrix(
    c(0.112028, 0.007643, 0.104721, 0.002144, 0.002659, 0.004071, 0, 0.3),
    nrow = 2, ncol = 4,
    dimnames = list(c("X->Y", "Y->X"), c("te", "ete", "se", "p-value"))
  )
expect_equal(coefs, exp_coefs, tolerance = 1e-6)
})


test_that("transfer_entropy handles missing values", {
  x[10] <- NA
  te <- calc_te(x, y, na.rm = TRUE)
  te2 <- calc_te(x, y, na.rm = FALSE)

  expect_false(is.na(te))
  expect_true(is.na(te2))
})

#################################
# Renyi Entropy
#################################

context("Renyi's Entropy")

test_that("transfer_entropy renyi is correctly specified", {
  # calc_te X->Y
  res <- calc_te(x, y, entropy = "renyi")
  expect_type(res, "double")
  expect_length(res, 1)
  expect_equal(res, 0.2530839, tolerance = 1e-6)

  # calc_te Y->X
  res <- calc_te(y, x, entropy = "renyi")
  expect_type(res, "double")
  expect_length(res, 1)
  expect_equal(res, 0.02494136, tolerance = 1e-6)

  # calc_ete X->Y
  res <- calc_ete(x, y, seed = 1234567890, entropy = "renyi")
  expect_type(res, "double")
  expect_length(res, 1)
  expect_equal(res, -0.072464, tolerance = 1e-6)

  # calc_ete Y->X
  res <- calc_ete(y, x, entropy = "renyi")
  expect_type(res, "double")
  expect_length(res, 1)
  expect_equal(res, -0.169475, tolerance = 1e-6)

  # transfer_entropy
  suppressWarnings({
    res <- transfer_entropy(x, y,
      lx = 1, ly = 1, entropy = "renyi", q = 0.5,
      nboot = 10, quiet = T, seed = 12345667
    )
  })

  # check types
  expect_true(is.transfer_entropy(res))

  # we have the all observations saved properly
  expect_equal(res$entropy, "renyi")
  expect_equal(res$obs$x, x)
  expect_equal(res$obs$y, y)
  expect_equal(res$nobs, n)

  # check the coefficients
  coefs <- coef(res)
  expect_true(is.matrix(coefs))
  expect_equal(dim(coefs), c(2, 4))

  # check bootstrapped results
  boot <- res$boot
  expect_true(is.matrix(boot))
  expect_equal(dim(boot), c(2, 10))

  # check values
  exp_coefs <- matrix(
    c(0.121448, 0.01247, 0.045051, -0.036961, 0.03854, 0.032827, 0.2, 0.9),
    nrow = 2, ncol = 4,
    dimnames = list(c("X->Y", "Y->X"), c("te", "ete", "se", "p-value"))
  )
  expect_equal(coefs, exp_coefs, tolerance = 1e-6)
})

#################################
# zoo and xts compatability
#################################

context("zoo & xts compatability")

test_that("Check that transfer_entropy takes zoos and xts", {
  x <- x[1:200]
  y <- y[1:200]
  x.date <- seq(
    from = as.Date("2010-01-01"),
    by = "day",
    length.out = length(x)
  )

  suppressWarnings({
    te_raw <- transfer_entropy(x, y, seed = 123, nboot = 10, quiet = T)
  })

  # ts
  x_ts <- ts(x, start = min(x.date), end = max(x.date))
  y_ts <- ts(y, start = min(x.date), end = max(x.date))
  suppressWarnings({
    te_ts <- transfer_entropy(x_ts, y_ts, seed = 123, nboot = 10, quiet = T)
  })
  expect_equal(te_raw, te_ts)

  # zoo
  x_zoo <- zoo::zoo(x, x.date)
  y_zoo <- zoo::zoo(y, x.date)

  suppressWarnings({
    te_zoo <- transfer_entropy(x_zoo, y_zoo, seed = 123, nboot = 10, quiet = T)
  })
  expect_equal(te_raw, te_zoo)

  # xts
  x_xts <- xts::xts(x, x.date)
  y_xts <- xts::xts(y, x.date)
  suppressWarnings({
    te_xts <- transfer_entropy(x_xts, y_xts, seed = 123, nboot = 10, quiet = T)
  })
  expect_equal(te_raw, te_xts)
})


test_that("Make sure earlier errors are not replicated", {
  # see also https://github.com/BZPaper/RTransferEntropy/issues/58
  x <- c(79652133, 88786612, 95234422, 99336996, 100764257, 105189366, 121472911,
         119542332, 119862125, 120657508, 124405340, 125345113, 132920670, 137487222)

  y <- c(211363, 217291, 226623, 230039, 239212, 247339, 255805, 264450, 282990,
         304316, 314135, 313509, 331670, 348884)

  # set.seed(123)
  # markov_boot_step(c(1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3), lx = 1, burn = 50)

  # RTransferEntropy:::te_shannon(x, lx = 1, y = y, ly = 1,
  #                              100, type = "quantiles", quantiles = c(5, 95),
  #                              bins = NULL,
  #                              limits = NULL, nboot = 100, burn = 50, quiet = TRUE)

  te_result <- transfer_entropy(x, y, nboot = 100, quiet = TRUE)
  # minimal test is that this doesnt throw an error!
  expect_equal(1, 1) # no note about empty test
})
