#' Set httr config parameters
#'
#' This is the main wrapper function used to override configuration settings used by the httr package.
#'
#' This function should be used when automatic configuration is not desired. A mypki file will be generated and verified for correctness. The certificate and private key are extracted from a PKCS#12 file and used to define the following httr package config settings: cainfo, sslcert, and sslkey
#'
#' @param ca_bundle string: the absolute file path to a Certificate Authority (CA) bundle (.crt).
#' @param pki_file string: the absolute file path to a pki certificate (.p12 or .pfx)
#' @param password string: the passphrase used to encrypt the private key of p12_file
#' @import httr
#' @export
#' @examples
#' library(rpki)
#' GET('https://your.pki.enabled.website/path/to/whatever')
#'
#' # When manual configuration is desired
#' rpki::manual_config_pki(ca_bundle="/path/to/certificate_authority.crt",
#'                      p12_file="/path/to/my/pki.p12",
#'                      password="my_pki_passphrase")
#' GET('https://your.pki.enabled.website/path/to/whatever')
#'
manual_config_pki <- function(ca_bundle = NULL, pki_file = NULL, password = NULL) {
  # check arguments
  if (any(typeof(ca_bundle) != 'character',
          length(ca_bundle) != 1,
          typeof(pki_file) != 'character',
          length(pki_file) != 1,
          (!is.null(password) & length(password) > 1)))
    stop('Unexpected arguments. CA bundle and PKI must be specified at minimum.')

  # verify mypki file
  mypki_file <- get_mypki_path()
  write_mypki(mypki_file, ca_bundle, pki_file)
  if (!is_valid_mypki(mypki_file, password)) {
    file.remove(mypki_file)
    stop()
  }

  set_httr_config(cacert = ca_bundle, pki_file = pki_file, pass = password)
}
