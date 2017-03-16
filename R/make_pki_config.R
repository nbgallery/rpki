make_pki_config <- function(cacert = NULL, p12_file = NULL, pass = NULL) {
  # read in p12 file
  if (!is.null(pass)) {
    p12 <- openssl::read_p12(p12_file, password = pass)
  } else {
    p12 <- openssl::read_p12(p12_file, password = getPass::getPass("Please enter your PKI Password: "))
  }

  # write out cert to temp files
  cert_file = tempfile()
  openssl::write_pem(p12$cert, path=cert_file)

  # write out private key in pkcs#8 format
  key_file = tempfile()
  openssl::write_pem(x=p12$key, path=key_file)

  # set httr config arguments globally so PKI authentication persists for the whole R session
  # cainfo = certificate authority (CA) file (.crt)
  # sslcert = certificate file (.pem)
  # sslkey = keyfile (.key but PEM formatted)
  httr::set_config(httr::config(cainfo=cacert, sslcert=cert_file, sslkey=key_file, sslcerttype="PEM"))
}
