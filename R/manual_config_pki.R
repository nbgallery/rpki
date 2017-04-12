#' Set httr config parameters
#'
#' A wrapper function that overrides configuration settings used by the httr package using a specified PKI certificate and Certificate Authority (CA) bundle.
#'
#' This function should only be used when automatic configuration is not desired. A mypki file will be generated and verified for correctness. The certificate and private key are extracted from a PKCS#12-formatted PKI file and used to define the following httr config settings: cainfo, sslcert, sslkey
#'
#' @param mypki_file string: absolute file path to save mypki configuration file. Defaults to the home directory
#' @param ca_file string: absolute file path to a Certificate Authority (CA) bundle
#' @param pki_file string: absolute file path to a pki certificate (.p12 or .pfx)
#' @param password string: passphrase used to encrypt the private key of p12_file
#' @import httr
#' @export
#' @examples
#' library(rpki)
#' manual_config_pki(ca_file = '/path/to/certificate_authority.crt',
#'                   p12_file = 'path/to/my/pki.p12',
#'                   password = 'my_pki_passphrase')
#' GET('https://your.pki.enabled.website/path/to/whatever')
#'
manual_config_pki <- function(mypki_file = 'HOME/.mypki',
                              ca_file = NULL,
                              pki_file = NULL,
                              password = NULL) {
  # check arguments
  if (any(typeof(ca_file) != 'character',
          length(ca_file) != 1,
          typeof(pki_file) != 'character',
          length(pki_file) != 1,
          (!is.null(password) & length(password) > 1)))
    stop('Unexpected arguments. CA bundle and PKI must be specified at minimum.')

  # verify mypki file
  mypki_file = ifelse(mypki_file == 'HOME/.mypki', get_mypki_path(), mypki_file)
  write_mypki(mypki_file = mypki_file, ca_file = ca_file, pki_file = pki_file)
  if (!is_valid_mypki(mypki_file, password)) {
    file.remove(mypki_file)
    stop('PKI configuration not set for httr')
  }

  set_httr_config(ca_file = ca_file, pki_file = pki_file, pass = password)
}
