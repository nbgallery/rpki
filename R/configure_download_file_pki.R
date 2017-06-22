#' Set download.file parameters
#'
#' Override default configuration settings used by download.file to allow for PKI-enabled use of install.packages().
#'
#' Default mypki configuration settings will be used. The PKI certificate file must be in PKCS#12 format. The download.file() method is changed to "curl" and the following extra settings are applied: cacert, cert, key, pass. See ?download.file for more information.
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
#' configure_download_file_pki() # will prompt for passphrase
#' download.file("https://httpbin.org/")
#' install.packages("my_private_package")
#'
#' library(rpki)
#' configure_download_file_pki(password = "my_pki_passphrase")
#' GET("http://httpbin.org/")
#' install.packages("my_private_package")
configure_download_file_pki <- function(mypki_file = NULL,
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

  # make download.file configuration changes
  set_download_file_config(ca_file = json_data$ca, pki_file = json_data$p12$path, pass = password)
}
