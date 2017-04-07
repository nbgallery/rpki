#' Set httr config parameters
#'
#' This is a wrapper function that automatically overrides configuration settings used by the httr package to allow working with PKI-enabled web services.
#'
#' This function should be called for automatic configuration. The PKI certificate and private key are extracted from a PKCS#12 file and used to define the following httr package config settings: cainfo, sslcert, and sslkey
#' @import httr
#' @export
#' @examples
#' library(rpki)
#' auto_config_pki()
#' GET('https://your.pki.enabled.website/path/to/whatever')
#'
auto_config_pki <- function() {
  mypki_file <- get_mypki_path()
  valid <- is_valid_mypki(mypki_file)
  if (!valid) {
    warning('Invalid mypki configuration.')
    valid <- create_mypki(mypki_file)
  }
  # set pki config options
  if (valid) {
    json_data <- jsonlite::fromJSON(txt = mypki_file)
    set_httr_config(cacert = json_data$ca, pki_file = json_data$p12$path)
  }
}
