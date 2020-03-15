#' Set download.file parameters
#'
#' Override default configuration settings used by \code{download.file()} to allow for PKI-enabled use of \code{install.packages()}.
#'
#' All arguments are optional. Default mypki configuration settings will be used unless otherwise specified. The PKI certificate file must be in PKCS#12 format. The arguments of \code{download.file()} are modified so that \code{method = "curl"} and the following extra curl command-line arguments are set: cacert, cert, key, pass. See \code{?download.file} for more information.
#'
#' This download method requires curl to be installed and added to the PATH environment variable. This is already done for most Linux/Mac OS's.
#'
#' If a mypki configuration file cannot be found, users are prompted for file paths to both a PKI certificate and a Certificate Authority (CA) bundle.
#' @param mypki_file string: absolute file path to save .mypki configuration file. Defaults to the home directory
#' @param pki_file string: absolute file path to a pki certificate
#' @param ca_file string: absolute file path to a Certificate Authority (CA) bundle
#' @param password string: passphrase used to encrypt/decrypt the PKI certificate
#' @param overwrite logical: force overwrite a pre-existing mypki configuration file if found. Defaults to FALSE
#' @import httr
#' @export
#' @examples
#' library(rpki)
#' pki_enable_download_file() # will prompt for passphrase
#' download.file("https://httpbin.org/")
#' install.packages("my_private_package")
#'
#' library(rpki)
#' pki_enable_download_file(password = "my_pki_passphrase")
#' GET("http://httpbin.org/")
#' install.packages("my_private_package")
pki_enable_download_file <- function(mypki_file = NULL,
                                     pki_file = NULL,
                                     ca_file = NULL,
                                     password = NULL,
                                     overwrite = FALSE) {
  dependency_check()

  mypki_file <- ifelse(is.null(mypki_file), get_config_path(), mypki_file) # defaults to home directory
  if (overwrite) {
    if (any(is.null(pki_file), is.null(ca_file))) {
      create_mypki(file = mypki_file)
    } else {
      write_mypki(mypki_file = mypki_file, ca_file = ca_file, pki_file = pki_file)
    }
  }
  # read from pre-existing mypki file
  valid <- is_valid_mypki(file = mypki_file, password = password)
  if (!valid) {
    stop(paste0("Invalid mypki configuration file at ", mypki_file))
  }
  json_data <- jsonlite::fromJSON(txt = mypki_file)

  # make download.file configuration changes
  set_download_file_config(ca_file = json_data$ca, pki_file = json_data$p12$path, pass = password)
}


#' @import openssl
#' @importFrom getPass getPass
set_download_file_config <- function(ca_file = NULL, pki_file = NULL, pass = NULL) {
  # get pki password, reuse the stored pki password if user has previously entered it
  if (!is.null(pass)) {
    options("rpki_password" = pass)
  }
  pass <- get_pki_password()
  # keep cert and private key in encrypted temp files for continued use during the session
  cert_file <- get_pki_cert(pki_file, pass)
  rsa_key_file <- get_pki_key(pki_file, pass)

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
