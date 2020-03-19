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
#' pki_enable_httr(pki_file = "my_pki.p12", ca_file = "my_ca.crt", password = "my_pki_passphrase")
#' GET("http://httpbin.org/")
pki_enable_httr <- function(pki_file = NULL,
                            ca_file = NULL,
                            password = NULL,
                            override = FALSE) {
  dependency_check()

  # manage password
  if (override) clear_pki_password()
  if (!is.null(password)) set_pki_password(password)

  # convert filepaths to absolute filepaths
  if (!is.null(ca_file)) ca_file <- normalizePath(ca_file)
  if (!is.null(pki_file)) pki_file <- normalizePath(pki_file)

  # create mypki file if necessary
  mypki_file <- get_config_path() # defaults to home directory
  if (override || !file.exists(mypki_file)) {
    if (file.exists(mypki_file)) file.remove(mypki_file)
    # pki_file and ca_file are required arguments if override is used
    if (is.null(pki_file) || is.null(ca_file)) {
      interactive_create_mypki(file = mypki_file)
    } else {
      write_mypki(mypki_file = mypki_file, ca_file = ca_file, pki_file = pki_file)
    }
  }

  # read from existing mypki file
  valid <- is_valid_mypki(file = mypki_file)
  if (!valid)
    stop(paste0("Invalid mypki configuration file at: ", mypki_file))

  json_data <- jsonlite::fromJSON(mypki_file)

  # clean up the configuration environment when session ends
  reg.finalizer(globalenv(), environment_cleanup, onexit = TRUE)

  # make httr configuration changes
  set_httr_config(ca_file = json_data$ca, pki_file = json_data$p12$path)
}


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
