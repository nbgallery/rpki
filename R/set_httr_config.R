set_httr_config <- function(cacert = NULL, p12_file = NULL, pass = NULL) {
  if (is.null(pass)) {
    p12 <- read_p12(p12_file,
                    password = getPass('Please enter your PKI Password: '))
  }
  else {
    if (!is.character(pass))
      stop('password argument not recognized. Must be a string')
    p12 <- read_p12(p12_file, password = pass)
  }

  # keep cert and private key in temp files for continued use during the session
  cert_file <- tempfile()
  write_pem(x = p12$cert, path = cert_file)
  key_file <- tempfile()
  write_pem(x = p12$key, path = key_file)

  # set httr config arguments globally so PKI authentication persists
  # for the whole R session.
  # Args:
  #   cainfo: certificate authority (CA) file (.crt)
  #   sslcert: certificate file (.pem)
  #   sslkey: keyfile (.key but PEM formatted)
  httr::set_config(httr::config(cainfo = cacert,
                                sslcert = cert_file,
                                sslkey = key_file))
}
