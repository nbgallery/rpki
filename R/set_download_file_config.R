#' @import openssl
#' @importFrom getPass getPass
set_download_file_config <- function(ca_file = NULL, pki_file = NULL, pass = NULL) {
  p12 <- tryCatch(
    if (is.null(pass)) {
      read_p12(file = pki_file, pass <- getPass('Enter PKI Password: '))
    } else {
      read_p12(file = pki_file, pass)
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
  key_file2 <- tempfile()
  #system(paste0('openssl rsa -in ', key_file, ' -out ', key_file2, '-des -passin pass:', pass, ' -passout pass:', pass), ignore.stdout = TRUE, ignore.stderr = TRUE)
  # write out encrypted RSA key file in PKCS#1 format
  system2('openssl', args = c('rsa',
                              '-in', key_file,
                              '-out', key_file2,
                              '-des',
                              '-passin', paste0('pass:', pass),
                              '-passout', paste0('pass:', pass)),
          stdout = NULL,
          stderr = NULL)

  # set download.file parameters globally so PKI authentication persists
  # for the entire R session.
  # Args:
  #   download.file.method: "curl"
  #   cacert: certificate authority (CA) file (.crt)
  #   cert: certificate file (.pem)
  #   key: keyfile (.key but PEM formatted)
  #   pass: pki passphrase
  options(download.file.method = "curl")
  options(download.file.extra = paste("--cacert", ca_file,
                                      "--cert", cert_file,
                                      "--key", key_file2,
                                      "--pass", pass,
                                      "-L"))
}
