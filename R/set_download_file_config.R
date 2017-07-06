#' @import openssl
#' @importFrom getPass getPass
set_download_file_config <- function(ca_file = NULL, pki_file = NULL, pass = NULL) {
  # reuse pki passphrase if user has previously entered it
  opt <- getOption('pki_passphrase')
  if (!is.null(opt)) {
    pass <- opt
  }

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

  # set pki passphrase to use during session
  options('pki_passphrase' = pass)

  # keep cert and private key in temp files for continued use during the session
  cert_file <- tempfile()
  write_pem(x = p12$cert, path = cert_file)
  key_file <- tempfile()
  write_pem(x = p12$key, path = key_file, password = pass)
  rsa_key_file <- tempfile()
  # write out encrypted RSA key file in PKCS#1 format
  system2('openssl', args = c('rsa',
                              '-in', key_file,
                              '-out', rsa_key_file,
                              '-des',
                              '-passin', paste0('pass:', pass),
                              '-passout', paste0('pass:', pass)),
          stdout = NULL,
          stderr = NULL)

  # set download.file options globally so they persist for the entire R session.
  # Args:
  #   download.file.method: "curl"
  #   cacert: certificate authority (CA) file (.crt)
  #   cert: certificate file (PEM format)
  #   key: keyfile (PEM format)
  #   pass: pki passphrase
  options(download.file.method = 'curl')
  options(download.file.extra = paste('--cacert', ca_file,
                                      '--cert', cert_file,
                                      '--key', rsa_key_file,
                                      '--pass', pass,
                                      '-L'))
}
