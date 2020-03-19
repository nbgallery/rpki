#' Set download.file parameters
#'
#' Override default configuration settings used by \code{download.file()} to allow for PKI-enabled use of \code{install.packages()}.
#'
#' All arguments are optional. Default mypki configuration settings will be used unless otherwise specified. The PKI certificate file must be in PKCS#12 format. The arguments of \code{download.file()} are modified so that \code{method = "curl"} and the following extra curl command-line arguments are set: cacert, cert, key, pass. See \code{?download.file} for more information.
#'
#' This download method requires curl to be installed and added to the PATH environment variable. This is already done for most Linux/Mac OS's.
#'
#' If a mypki configuration file cannot be found, users are prompted for file paths to both a PKI certificate and a Certificate Authority (CA) bundle.
#' @param pki_file string: filepath to a pki certificate
#' @param ca_file string: filepath to a Certificate Authority (CA) bundle
#' @param password string: passphrase used to encrypt/decrypt the PKI certificate
#' @param override logical: force overwrite a pre-existing mypki configuration file if found. (Default: FALSE)
#' @export
#' @examples
#' library(rpki)
#' pki_enable_download_file() # will prompt for passphrase
#' install.packages("my_private_package")
#'
#' library(rpki)
#' pki_enable_download_file(pki_file = "my_pki.p12", ca_file = "my_ca.crt", password = "my_pki_passphrase")
#' install.packages("my_private_package")
pki_enable_download_file <- function(pki_file = NULL,
                                     ca_file = NULL,
                                     password = NULL,
                                     override = FALSE) {
  dependency_check()

  # manage password
  if(override) clear_pki_password()
  if(!is.null(password)) set_pki_password(password)

  # convert filepaths to absolute filepaths
  if(!is.null(ca_file)) ca_file <- normalizePath(ca_file)
  if(!is.null(pki_file)) pki_file <- normalizePath(pki_file)

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
    stop(paste0("Invalid mypki configuration file at ", mypki_file))

  json_data <- jsonlite::fromJSON(mypki_file)

  # clean up the configuration environment when session ends
  reg.finalizer(globalenv(), environment_cleanup, onexit = TRUE)

  # make download.file configuration changes
  set_download_file_config(ca_file = json_data$ca, pki_file = json_data$p12$path)
}


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
