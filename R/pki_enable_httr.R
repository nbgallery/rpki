#' Set httr config parameters
#'
#' Override configuration settings used by the 'httr' package to allow working with PKI-enabled web services.
#'
#' Default mypki configuration settings will be used unless otherwise specified. The PKI certificate file must be in PKCS#12 format. The following \code{httr::config} settings are modified: cainfo, sslcert, sslkey.
#'
#' If a mypki configuration file cannot be found, users are prompted for filepaths to a PKI certificate and a Certificate Authority (CA) bundle.
#' @param pki_file string: file path to a pki certificate
#' @param ca_file string: file path to a Certificate Authority (CA) bundle
#' @param password string: passphrase used to encrypt/decrypt the private key of the PKI certificate
#' @param override logical: force override of a pre-existing mypki configuration file if found.
#' @import httr
#' @export
#' @examples
#' library(rpki)
#' pki_enable_httr() # will prompt for passphrase
#' GET("http://httpbin.org/")
#'
#' library(rpki)
#' pki_enable_httr(pki_file = "my_pki.p12",
#'                 ca_file = "my_ca.crt",
#'                 password = "my_pki_passphrase")
#' GET("http://httpbin.org/")
pki_enable_httr <- function(pki_file = NULL,
                            ca_file = NULL,
                            password = NULL,
                            override = FALSE) {
  dependency_check()
  mypki_file <- configure_mypki(pki_file, ca_file, password, override)
  json_data <- jsonlite::fromJSON(mypki_file)
  # clean up the configuration environment when session ends
  reg.finalizer(globalenv(), environment_cleanup, onexit = TRUE)
  # make httr configuration changes
  set_httr_config(ca_file = json_data$ca, pki_file = json_data$p12$path)
}


# the associated addin function for RStudio users
addin_pki_enable_httr <- function() {
  continue <- rstudioapi::showQuestion("rpki", "Please select your PKI certificate (*.p12)")
  if (continue) {
    p12_file <- rstudioapi::selectFile(
      caption = "PKI File",
      label = "Select",
      path = rstudioapi::getActiveProject(),
      filter = "*.p12",
      existing = TRUE
    )
  }
  continue <- rstudioapi::showQuestion("rpki", "Please select your Certificate Authority (CA) bundle (*.crt)")
  if (continue) {
    ca_file <- rstudioapi::selectFile(
      caption = "CA Bundle",
      label = "Select",
      path = rstudioapi::getActiveProject(),
      filter = "*.crt",
      existing = TRUE
    )
  }
  pki_enable_httr(pki_file = p12_file, ca_file = ca_file, override = TRUE)
}


set_httr_config <- function(ca_file = NULL, pki_file = NULL) {
  # reuse pki passphrase if user has previously entered it
  pass <- get_pki_password()
  # keep cert and private key in encrypted temp files for continued use during the session
  cert_file <- get_pki_cert(pki_file)
  rsa_key_file <- get_pki_key(pki_file)

  # set httr config arguments globally so PKI authentication persists
  # for the entire R session.
  # Args:
  #   cainfo: certificate authority (CA) file (.crt)
  #   sslcert: certificate file (.pem)
  #   sslkey: keyfile (.key but PEM formatted)
  #   keypasswd: pki passphrase
  httr::set_config(httr::config(
    cainfo = ca_file,
    sslcert = cert_file,
    sslkey = rsa_key_file,
    keypasswd = pass
  ))
}
