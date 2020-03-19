#' Set download.file parameters
#'
#' Override default configuration settings used by \code{download.file()} to allow for PKI-enabled use of \code{install.packages()}.
#'
#' Default mypki configuration settings will be used unless otherwise specified. The PKI certificate file must be in PKCS#12 format. The arguments of \code{download.file()} are modified so that \code{method = "curl"} and the following extra curl command-line arguments are set: cacert, cert, key, pass. See \code{?download.file} for more information.
#'
#' This download method requires curl to be installed and added to the PATH environment variable. This is already done for most Linux/Mac distributions.
#'
#' If a mypki configuration file cannot be found, users are prompted for filepaths to a PKI certificate and a Certificate Authority (CA) bundle.
#' @param pki_file string: filepath to a pki certificate
#' @param ca_file string: filepath to a Certificate Authority (CA) bundle
#' @param password string: passphrase used to encrypt/decrypt the PKI certificate
#' @param override logical: force overwrite a pre-existing mypki configuration file if found.
#' @export
#' @examples
#' library(rpki)
#' pki_enable_download_file() # will prompt for passphrase
#' install.packages("my_private_package")
#'
#' library(rpki)
#' pki_enable_download_file(pki_file = "my_pki.p12",
#'                          ca_file = "my_ca.crt",
#'                          password = "my_pki_passphrase")
#' install.packages("my_private_package")
pki_enable_download_file <- function(pki_file = NULL,
                                     ca_file = NULL,
                                     password = NULL,
                                     override = FALSE) {
  dependency_check()
  mypki_file <- configure_mypki(pki_file, ca_file, password, override)
  json_data <- jsonlite::fromJSON(mypki_file)
  # clean up the configuration environment when session ends
  reg.finalizer(globalenv(), environment_cleanup, onexit = TRUE)
  # make download.file configuration changes
  set_download_file_config(ca_file = json_data$ca, pki_file = json_data$p12$path)
}


# the associated addin function for RStudio users
addin_pki_enable_download_file <- function() {
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
  pki_enable_download_file(pki_file = p12_file, ca_file = ca_file, override = TRUE)
}


set_download_file_config <- function(ca_file = NULL, pki_file = NULL) {
  # reuse pki passphrase if user has previously entered it
  pass <- get_pki_password()
  # keep cert and private key in encrypted temp files for continued use during the session
  cert_file <- get_pki_cert(pki_file)
  rsa_key_file <- get_pki_key(pki_file)

  # set download.file options globally so they persist for the entire R session.
  # Args:
  #   download.file.method: "curl"
  #   cacert: certificate authority (CA) file (.crt)
  #   cert: certificate file (PEM format)
  #   key: keyfile (PEM format)
  #   pass: pki passphrase
  options(download.file.method = "curl")
  options(download.file.extra = paste(
    "--cacert", ca_file,
    "--cert", cert_file,
    "--key", rsa_key_file,
    "--pass", pass,
    "-L"
  ))
}
