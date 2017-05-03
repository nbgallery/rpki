#' Set httr config parameters
#'
#' Override configuration settings used by the 'httr' package to allow working with PKI-enabled web services, based on the supplied arguments.
#'
#' This function should only be used when default arguments are not desired using \code{auto_config_pki()}. A mypki file is generated based on the file paths of a PKI certificate and Certificate Authority bundle. At a minimum, \code{pki_file} and \code{ca_file} must be specified. If \code{mypki_file} is not specified, a mypki configuration file is generated in the user's home directory. The PKI certificate must be in PKCS#12 format. The following 'httr' config settings get modified: cainfo, sslcert, sslkey
#'
#' @param pki_file string: absolute file path to a pki certificate
#' @param ca_file string: absolute file path to a Certificate Authority (CA) bundle
#' @param password string: passphrase used to encrypt/decrypt the private key of the pki certificate
#' @param mypki_file string: absolute file path to save mypki configuration file. Defaults to the home directory
#' @import httr
#' @export
#' @examples
#' \dontrun{
#' library(rpki)
#' manual_config_pki(pki_file = 'path/to/my/pki.p12',
#'                   ca_file = '/path/to/certificate_authority.crt',
#'                   password = 'my_pki_passphrase')
#' GET('https://your.pki.enabled.website/path/to/whatever')
#' }
#'
manual_config_pki <- function(pki_file = NULL,
                              ca_file = NULL,
                              password = NULL,
                              mypki_file = NULL) {
  # check arguments
  if (any(typeof(ca_file) != 'character',
          length(ca_file) != 1,
          typeof(pki_file) != 'character',
          length(pki_file) != 1,
          (!is.null(password) & length(password) > 1)))
    stop('Unexpected arguments. CA bundle and PKI must be specified at minimum.')

  # verify mypki file
  mypki_file = ifelse(is.null(mypki_file), get_mypki_path(), mypki_file)
  write_mypki(mypki_file = mypki_file, ca_file = ca_file, pki_file = pki_file)
  if (!is_valid_mypki(file = mypki_file, password = password)) {
    file.remove(mypki_file)
    stop('PKI configuration not set for httr')
  }

  set_httr_config(ca_file = ca_file, pki_file = pki_file, pass = password)
}
