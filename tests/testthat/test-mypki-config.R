context('mypki configuration')

p12.file <- 'fred.p12'
p12.password = 'fred'
ca.file <- 'root-ca.crt'

test_that('Verify whether or not a mypki file is valid', {
  expect_true(is_valid_mypki('sample_valid_mypki.txt'))
  expect_false(is_valid_mypki('sample_invalid_mypki.txt'))
})

test_that('Using a pre-existing mypki file to set httr_options', {
  mypki <- 'sample_valid_mypki.txt'
  pki_enable_httr(mypki_file = mypki, password = p12.password)

  expect_false(is.null(getOption('httr_config')))
  reset_config()
})

test_that('Force the creation of a new mypki file', {
  mypki <- tempfile()
  pki_enable_httr(mypki_file = mypki,
                     pki_file = p12.file,
                     ca_file = ca.file,
                     password = p12.password,
                     overwrite = TRUE)
  expect_true(is_valid_mypki(mypki))
  reset_config()
})

test_that('A mypki file is generated with the correct json format', {
  mypki <- tempfile()
  pki_enable_httr(mypki_file = mypki,
                     pki_file = p12.file,
                     ca_file = ca.file,
                     password = p12.password,
                     overwrite = TRUE)
  json_data <- jsonlite::fromJSON(mypki)

  expect_true(('ca' %in% names(json_data)))
  expect_true(('p12' %in% names(json_data)))
  expect_true(("path" %in% names(json_data$p12)))
  reset_config()
})
