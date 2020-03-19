context("mypki configuration")

p12.file <- "fred.p12"
p12.password <- "fred"
ca.file <- "root-ca.crt"

test_that("Verify whether or not a mypki file is valid", {
  set_pki_password(p12.password)
  expect_true(is_valid_mypki("sample_valid_mypki.txt"))
  expect_false(is_valid_mypki("sample_invalid_mypki.txt"))
})

test_that("Force the creation of a new mypki file", {
  pki_enable_httr(
    pki_file = p12.file,
    ca_file = ca.file,
    password = p12.password,
    override = TRUE
  )
  mypki <- get_config_path()
  expect_true(is_valid_mypki(mypki))
  httr::reset_config()
})

test_that("A mypki file is generated with the correct json format", {
  pki_enable_httr(
    pki_file = p12.file,
    ca_file = ca.file,
    password = p12.password,
    override = TRUE
  )
  mypki <- get_config_path()
  json_data <- jsonlite::fromJSON(mypki)

  expect_true(("ca" %in% names(json_data)))
  expect_true(("p12" %in% names(json_data)))
  expect_true(("path" %in% names(json_data$p12)))
  httr::reset_config()
})
