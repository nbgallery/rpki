context('httr configuration')

p12.file <- 'fred.p12'
p12.password = 'fred'
ca.file <- 'root-ca.crt'

test_that('the temporary SSL cert set by httr_options matches the PKI file', {
  mypki <- tempfile()
  configure_httr_pki(mypki_file = mypki,
                     pki_file = p12.file,
                     ca_file = ca.file,
                     password = p12.password,
                     overwrite = TRUE)
  my.configuration <- .Options$httr_config
  my.cert <- read_cert(my.configuration$options$sslcert)
  p12 <- read_p12(file = p12.file, password = p12.password)

  expect_identical(my.cert, p12$cert)
  reset_config()
})

test_that('the temporary SSL key set by httr_options matches the PKI file', {
  mypki <- tempfile()
  configure_httr_pki(mypki_file = mypki,
                     pki_file = p12.file,
                     ca_file = ca.file,
                     password = p12.password,
                     overwrite = TRUE)
  my.configuration <- .Options$httr_config
  my.key <- read_key(my.configuration$options$sslkey)
  p12 <- read_p12(file = p12.file, password = p12.password)

  expect_identical(my.key, p12$key)
  reset_config()
})

test_that('the certificate authority bundle set by httr_options matches the CA bundle that was originally specified', {
  mypki <- tempfile()
  configure_httr_pki(mypki_file = mypki,
                     pki_file = p12.file,
                     ca_file = ca.file,
                     password = p12.password,
                     overwrite = TRUE)
  my.configuration <- .Options$httr_config
  my.cert.bundle <- read_cert_bundle(my.configuration$options$cainfo)

  expect_identical(my.cert.bundle, read_cert_bundle(ca.file))
  reset_config()
})

test_that('the cert and key files are removed when the package is detached', {
  mypki <- tempfile()
  configure_httr_pki(mypki_file = mypki,
                     pki_file = p12.file,
                     ca_file = ca.file,
                     password = p12.password,
                     overwrite = TRUE)
  old.configuration <- getOption('httr_config')$options
  detach('package:rpki', character.only = TRUE)
  my.opt <- getOption('httr_config')$options
  expect_length(my.opt, 0)
  expect_false(file.exists(old.configuration$sslcert))
  expect_false(file.exists(old.configuration$sslkey))
  reset_config()
})
