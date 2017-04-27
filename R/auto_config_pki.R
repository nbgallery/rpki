#' Set httr config parameters
#'
#' A wrapper function that automatically overrides configuration settings used by the httr package to allow working with PKI-enabled web services.
#'
#' This function should be called for automatic configuration. The PKI certificate and private key are extracted from a PKCS#12-formatted PKI file and used to define the following httr config settings: cainfo, sslcert, sslkey
#' @param password string: passphrase used to encrypt the private key of p12_file. Optional argument that defaults to NULL.
#' @import httr
#' @export
#' @examples
#' library(rpki)
#' auto_config_pki()
#' GET('https://your.pki.enabled.website/path/to/whatever')
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
