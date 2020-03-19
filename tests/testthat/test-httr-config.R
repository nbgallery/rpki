context("httr configuration")

p12.file <- "fred.p12"
p12.password <- "fred"
ca.file <- "root-ca.crt"

test_that("httr_config options get set in options()", {
  pki_enable_httr(
    pki_file = p12.file,
    ca_file = ca.file,
    password = p12.password,
    override = TRUE
  )
  my.configuration <- getOption("httr_config")
  expect_false(is.null(my.configuration))
  httr::reset_config()
})

test_that("the SSL cert set by httr_options matches the PKI file", {
  pki_enable_httr(
    pki_file = p12.file,
    ca_file = ca.file,
    password = p12.password,
    override = TRUE
  )
  my.configuration <- getOption("httr_config")
  my.cert <- openssl::read_cert(my.configuration$options$sslcert)
  p12 <- openssl::read_p12(file = p12.file, password = p12.password)

  expect_identical(my.cert, p12$cert)
  httr::reset_config()
})

test_that("the SSL key set by httr_options matches the PKI file", {
  pki_enable_httr(
    pki_file = p12.file,
    ca_file = ca.file,
    password = p12.password,
    override = TRUE
  )
  my.configuration <- getOption("httr_config")
  my.key <- openssl::read_key(my.configuration$options$sslkey, password = p12.password)
  p12 <- openssl::read_p12(file = p12.file, password = p12.password)

  expect_identical(my.key, p12$key)
  httr::reset_config()
})

test_that("the certificate authority bundle set by httr_options matches the CA bundle that was originally specified", {
  pki_enable_httr(
    pki_file = p12.file,
    ca_file = ca.file,
    password = p12.password,
    override = TRUE
  )
  my.configuration <- getOption("httr_config")
  my.cert.bundle <- openssl::read_cert_bundle(my.configuration$options$cainfo)
  expect_identical(my.cert.bundle, openssl::read_cert_bundle(ca.file))
  httr::reset_config()
})

test_that("the cert and key files are removed when the package is detached", {
  pki_enable_httr(
    pki_file = p12.file,
    ca_file = ca.file,
    password = p12.password,
    override = TRUE
  )
  old.configuration <- getOption("httr_config")$options
  detach("package:rpki", character.only = TRUE)
  my.opt <- getOption("httr_config")
  expect_null(my.opt)
  expect_false(file.exists(old.configuration$sslcert))
  expect_false(file.exists(old.configuration$sslkey))
  httr::reset_config()
})
