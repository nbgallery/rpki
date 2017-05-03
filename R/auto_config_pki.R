#' Set httr config parameters
#'
#' Override configuration settings used by the 'httr' package to allow working with PKI-enabled web services.
#'
#' Default mypki configuration settings will be used. If no password is provided (\code{password = NULL}), the PKI certificate specified by the mypki configuration file is assumed to be unencrypted. The PKI certificate file must be in PKCS#12 format. The following 'httr' config settings get modified: cainfo, sslcert, sslkey.
#'
#' If a mypki configuration file cannot be found, users are prompted for file paths to both a PKI certificate and a Certificate Authority (CA) bundle.
#' @param password string: passphrase used to encrypt/decrypt the private key of a PKI certificate
#' @import httr
#' @export
#' @examples
#' \dontrun{
#' library(rpki)
#' auto_config_pki()
#' GET('https://your.pki.enabled.website/path/to/whatever')
#' }
#'
auto_config_pki <- function(password = NULL) {
  mypki_file <- get_mypki_path()
  valid <- is_valid_mypki(file = mypki_file, password = password)
  if (!valid) {
    message('Invalid mypki configuration.')
    valid <- create_mypki(file = mypki_file)
  }
  # set pki config options
  if (valid) {
    json_data <- jsonlite::fromJSON(txt = mypki_file)
    set_httr_config(ca_file = json_data$ca, pki_file = json_data$p12$path, pass = password)
  } else
    stop('PKI configuration not set for httr')
}
