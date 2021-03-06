% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pki_enable_download_file.R
\name{pki_enable_download_file}
\alias{pki_enable_download_file}
\title{Set download.file parameters}
\usage{
pki_enable_download_file(
  pki_file = NULL,
  ca_file = NULL,
  password = NULL,
  override = FALSE
)
}
\arguments{
\item{pki_file}{string: filepath to a pki certificate}

\item{ca_file}{string: filepath to a Certificate Authority (CA) bundle}

\item{password}{string: passphrase used to encrypt/decrypt the PKI certificate}

\item{override}{logical: force overwrite a pre-existing mypki configuration file if found.}
}
\description{
Override default configuration settings used by \code{download.file()} to allow for PKI-enabled use of \code{install.packages()}.
}
\details{
Default mypki configuration settings will be used unless otherwise specified. The PKI certificate file must be in PKCS#12 format. The arguments of \code{download.file()} are modified so that \code{method = "curl"} and the following extra curl command-line arguments are set: cacert, cert, key, pass. See \code{?download.file} for more information.

This download method requires curl to be installed and added to the PATH environment variable. This is already done for most Linux/Mac distributions.

If a mypki configuration file cannot be found, users are prompted for filepaths to a PKI certificate and a Certificate Authority (CA) bundle.
}
\examples{
library(rpki)
pki_enable_download_file() # will prompt for passphrase
install.packages("my_private_package")

library(rpki)
pki_enable_download_file(pki_file = "my_pki.p12",
                         ca_file = "my_ca.crt",
                         password = "my_pki_passphrase")
install.packages("my_private_package")
}
