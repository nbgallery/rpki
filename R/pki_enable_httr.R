#' Set httr config parameters
#'
#' Override configuration settings used by the 'httr' package to allow working with PKI-enabled web services.
#'
#' All arguments are optional. Default mypki configuration settings will be used unless otherwise specified. The PKI certificate file must be in PKCS#12 format. The following \code{httr::config} settings are modified: cainfo, sslcert, sslkey.
#'
#' If a mypki configuration file cannot be found, users are prompted for file paths to both a PKI certificate and a Certificate Authority (CA) bundle.
#' @param mypki_file string: absolute file path to save mypki configuration file. Defaults to the home directory
#' @param pki_file string: absolute file path to a pki certificate
#' @param ca_file string: absolute file path to a Certificate Authority (CA) bundle
#' @param password string: passphrase used to encrypt/decrypt the private key of the PKI certificate
#' @param overwrite logical: overwrite a pre-existing mypki configuration file, if found. Defaults to FALSE
#' @import httr
#' @export
#' @examples
#' library(rpki)
#' pki_enable_httr() # will prompt for passphrase
#' GET("http://httpbin.org/")
#'
#' library(rpki)
#' pki_eable_httr(password = "my_pki_passphrase")
#' GET("http://httpbin.org/")
#'
pki_enable_httr <- function(mypki_file = NULL,
                               pki_file = NULL,
                               ca_file = NULL,
                               password = NULL,
                               overwrite = FALSE) {
  mypki_file <- ifelse(is.null(mypki_file), get_mypki_path(), mypki_file) # defaults to home directory
  if (overwrite) {
    if (any(is.null(pki_file), is.null(ca_file))) {
      create_mypki(file = mypki_file)
    } else
      write_mypki(mypki_file = mypki_file, ca_file = ca_file, pki_file = pki_file)
  }
  # read from pre-existing mypki file
  valid <- is_valid_mypki(file = mypki_file, password = password)
  if (!valid)
    stop(paste0('Invalid mypki configuration at ', mypki_file, '. Set overwrite = TRUE'))
  json_data <- jsonlite::fromJSON(txt = mypki_file)

  # clean up the configuration environment when session ends
  reg.finalizer(globalenv(), environment_cleanup, onexit = TRUE)

  # make httr configuration changes
  set_httr_config(ca_file = json_data$ca, pki_file = json_data$p12$path, pass = password)
}


#' @import openssl
#' @importFrom getPass getPass
set_httr_config <- function(ca_file = NULL, pki_file = NULL, pass = NULL) {
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

  # store pki passphrase to use during session
  options('pki_passphrase' = pass)

  # keep cert and private key in temp files for continued use during the session
  cert_file <- tempfile()
  system2('openssl', args = c('pkcs12',
                              '-in', pki_file,
                              '-out', cert_file,
                              '-clcerts', '-nokeys', '-nomacver',
                              '-passin', paste0('pass:', pass)),
          stdout = NULL,
          stderr = NULL)

  key_file <- tempfile()
  system2('openssl', args = c('pkcs12',
                              '-in', pki_file,
                              '-out', key_file,
                              '-nocerts', '-nomacver',
                              '-passin', paste0('pass:', pass),
                              '-passout', paste0('pass:', pass)),
          stdout = NULL,
          stderr = NULL)

  # write out encrypted RSA key file in PKCS#1 format
  rsa_key_file <- tempfile()
  system2('openssl', args = c('rsa',
                              '-in', key_file,
                              '-out', rsa_key_file,
                              '-des',
                              '-passin', paste0('pass:', pass),
                              '-passout', paste0('pass:', pass)),
          stdout = NULL,
          stderr = NULL)

  # set httr config arguments globally so PKI authentication persists
  # for the entire R session.
  # Args:
  #   cainfo: certificate authority (CA) file (.crt)
  #   sslcert: certificate file (.pem)
  #   sslkey: keyfile (.key but PEM formatted)
  #   keypasswd: pki passphrase
  httr::set_config(httr::config(cainfo = ca_file,
                                sslcert = cert_file,
                                sslkey = rsa_key_file,
                                keypasswd = pass))
}


