#' Set httr config parameters
#'
#' This is the main wrapper function used to override configuration settings used by the httr paclage.
#'
#' When the package is first loaded via the library() call, rpki attempts to search for and use a pre-existing .mypki configuration file. If not found or the file is determined to be invalid, the user will be prompted for file paths to a certificate authority bundle and a PKI file. The certificate and private key are extracted from a PKCS#12 file and used to define the following httr package config settings: cainfo, sslcert, and sslkey
#'
#' @param cacert string: the absolute file path to a Certificate Authority (CA) bundle (.crt).
#' @param p12_file string: the absolute file path to a PKCS#12 certificate (.p12 or .pfx)
#' @export
#' @examples
#' library(rpki)
#' GET('https://your.pki.enabled.website/path/to/whatever')
#'
#' # When manual configuration is desired
#' rpki::set_pki_config(cacert="/path/to/certificate_authority.crt", p12_file="/path/to/pki.p12")
#' GET('https://your.pki.enabled.website/path/to/whatever')
#'

set_pki_config <- function(cacert = NULL, p12_file = NULL) {
  # check arguments
  if(any(is.null(cacert), is.null(p12_file), typeof(cacert) != "character", typeof(p12_file) != "character"))
    stop("Unexpected arguments passed to set_pki_config(). Consult documentation.")

  # use openssl package to convert p12/pfx pki file to pem files for httr to use
  if ( !(tools::file_ext(p12_file) %in% c("p12","pfx")) ) {
    stop("PKI file not recognized. File must be PKCS#12 formatted and have a .p12 or .pfx file extension")
  }

  p12 <- openssl::read_p12(p12_file, password = getPass::getPass("Please enter your PKI Password: "))

  # write out cert to temp files
  cert_file = tempfile()
  openssl::write_pem(p12$cert, path=cert_file)

  # write out private key in pkcs#8 format
  key_file = tempfile()
  openssl::write_pem(x=p12$key, path=key_file)

  # set httr config arguments globally so PKI authentication persists for the whole R session
    # cainfo = certificate authority (CA) file (.crt)
    # sslcert = certificate file (.pem)
    # sslkey = keyfile (.key but PEM formatted)
  httr::set_config(httr::config(cainfo=cacert, sslcert=cert_file, sslkey=key_file, sslcerttype="PEM"))
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
  set_pki_config(json_data$ca, json_data$p12$path)
}
