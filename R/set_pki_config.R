#' Set httr config parameters
#'
#' This is the main wrapper function used to override configuration settings used by the httr package.
#'
#' This function should only be called when automatic configuration via the library() call is not desired. A .mypki file will be generated and verified for correctness. The certificate and private key are extracted from a PKCS#12 file and used to define the following httr package config settings: cainfo, sslcert, and sslkey
#'
#' @param ca_bundle string: the absolute file path to a Certificate Authority (CA) bundle (.crt).
#' @param p12_file string: the absolute file path to a PKCS#12 certificate (.p12 or .pfx)
#' @param password string: the passphrase used to encrypt the private key of p12_file
#' @export
#' @examples
#' library(rpki)
#' GET('https://your.pki.enabled.website/path/to/whatever')
#'
#' # When manual configuration is desired
#' rpki::set_pki_config(ca_bundle="/path/to/certificate_authority.crt", p12_file="/path/to/my/pki.p12", password="my_pki_passphrase")
#' GET('https://your.pki.enabled.website/path/to/whatever')
#'
set_pki_config <- function(ca_bundle = NULL, p12_file = NULL, password = NULL) {
  # check arguments
  if(any(is.null(ca_bundle), is.null(p12_file), typeof(ca_bundle) != "character", typeof(p12_file) != "character"))
    stop("Unexpected arguments. CA bundle and PKI must be specified at minimum. Consult documentation.")

  # write mypki file and check its validity
  mypki <- get_config_path()
  write_mypki(mypki_file=mypki, ca_file=ca_bundle, pki_file=p12_file)
  if(!is_valid_mypki(mypki))
    stop("Invalid file paths.")


  if (is.null(password))
    make_pki_config(ca_bundle, p12_file)
  else {
    if (!is.character(password))
      stop("password argument not recognized. Must be a string")
    make_pki_config(ca_bundle, p12_file, password)
  }
}


# this hook is automatically called when the package is attached ( by calling library() )
.onAttach <- function(libname, pkgname) {
  mypki_file <- get_config_path()

  # check mypki file validity
  if (!is_valid_mypki(mypki_file)) {
    packageStartupMessage(paste0("Invalid mypki configuration. Creating new file at ", mypki_file))
    create_mypki(mypki_file)
  }

  # set pki config options
  json_data <- jsonlite::fromJSON(txt = mypki_file)
  make_pki_config(json_data$ca, json_data$p12$path)
}
