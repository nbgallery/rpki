context('connection')

p12.password = 'fred'
ca.file <- 'root-ca.crt'

test_that('Can still connect to unsecured websites', {
  mypki <- tempfile()
  pki_enable_httr(mypki_file = mypki,
                     pki_file = 'fred.p12',
                     ca_file = ca.file,
                     password = p12.password,
                     overwrite = TRUE)
  response <- GET('http://httpbin.org')
  expect_equal(response$status_code, 200)
  reset_config()
})

test_that('Check p12 filename with whitespace', {
  mypki <- tempfile()
  pki_enable_httr(mypki_file = mypki,
                  pki_file = 'fred flintstone.p12',
                  ca_file = ca.file,
                  password = p12.password,
                  overwrite = TRUE)
  response <- GET('http://httpbin.org')
  expect_equal(response$status_code, 200)
  reset_config()
})
