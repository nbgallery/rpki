% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pki_enable_httr.R
\name{pki_enable_httr}
\alias{pki_enable_httr}
\title{Set httr config parameters}
\usage{
pki_enable_httr(
  pki_file = NULL,
  ca_file = NULL,
  password = NULL,
  override = FALSE
)
}
\arguments{
\item{pki_file}{string: file path to a pki certificate}

\item{ca_file}{string: file path to a Certificate Authority (CA) bundle}

\item{password}{string: passphrase used to encrypt/decrypt the private key of the PKI certificate}

\item{override}{logical: force override of a pre-existing mypki configuration file if found.}
}
\description{
Override configuration settings used by the 'httr' package to allow working with PKI-enabled web services.
}
\details{
Default mypki configuration settings will be used unless otherwise specified. The PKI certificate file must be in PKCS#12 format. The following \code{httr::config} settings are modified: cainfo, sslcert, sslkey.

If a mypki configuration file cannot be found, users are prompted for filepaths to a PKI certificate and a Certificate Authority (CA) bundle.
}
\examples{
library(rpki)
pki_enable_httr() # will prompt for passphrase
GET("http://httpbin.org/")

library(rpki)
pki_enable_httr(pki_file = "my_pki.p12",
                ca_file = "my_ca.crt",
                password = "my_pki_passphrase")
GET("http://httpbin.org/")
}
