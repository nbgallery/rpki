#' @import openssl
#' @importFrom getPass getPass
set_httr_config <- function(ca_file = NULL, pki_file = NULL, pass = NULL) {
  p12 <- tryCatch(
    if (is.null(pass)) {
      read_p12(file = pki_file, password = getPass('Enter PKI Password: '))
    } else {
      read_p12(file = pki_file, password = pass)
    },
    error = function(e) {
      stop('Incorrect password or unrecognized PKI file format.')
    }
  )

  # keep cert and private key in temp files for continued use during the session
  cert_file <- tempfile()
  write_pem(x = p12$cert, path = cert_file)
  key_file <- tempfile()
  write_pem(x = p12$key, path = key_file, password = pass)

  # set httr config arguments globally so PKI authentication persists
  # for the whole R session.
  # Args:
  #   cainfo: certificate authority (CA) file (.crt)
  #   sslcert: certificate file (.pem)
  #   sslkey: keyfile (.key but PEM formatted)
  httr::set_config(httr::config(cainfo = ca_file,
                                sslcert = cert_file,
                                sslkey = key_file,
                                keypasswd = pass))
}
