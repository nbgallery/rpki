context('connection')

p12.file <- 'fred.p12'
p12.password = 'fred'
ca.file <- 'root-ca.crt'

test_that('Can still connect to unsecured websites', {
  mypki <- tempfile()
  configure_httr_pki(mypki_file = mypki,
                     pki_file = p12.file,
                     ca_file = ca.file,
                     password = p12.password,
                     overwrite = TRUE)
  response <- GET('http://httpbin.org')
  expect_equal(response$status_code, 200)
  reset_config()
})
