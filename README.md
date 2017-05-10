# rpki
rpki is a wrapper package that PKI-enables the httr package. Conceptually, rpki is similar to the Ruby [MyPKI](https://github.com/nbgallery/mypki) package and Python [pypki2](https://github.com/nbgallery/pypki2) package, and is intended to use the same mypki configuration file.

## Details
rpki can run in both interactive and non-interactive R sessions. The default behavior of rpki is to override the config() settings of httr using the PKI settings found in a .mypki configuration file. It will attempt to search for and use a pre-existing .mypki configuration file located in the home directory (~/.mypki). If the configuration file is not found or is invalid (wrong format, nonexistent file paths, .etc), the user will be prompted for file paths to a certificate authority bundle and a PKI file. rpki sets the following httr config settings
* cainfo
* sslcert
* sslkey

### mypki Configuration File
rpki expects a mypki configuration file to be json formatted and at minimum specify the absolute file paths to a Certificate Authority (CA) bundle and a PKCS12 digital certificate.
```json
{
  "ca": "/path/to/certificate_authority_bundle.crt",
  "p12": {
    "path": "/path/to/pki_digital_certificate.p12"
  }
}
```

## Examples
### Fetching a URL
```r
library(rpki)
configure_httr_pki() # will prompt for pki passphrase if necessary
GET("https://your.pki.enabled.website/path/to/whatever")
```
#### Explicitly provide the pki passphrase
```r
library(rpki)
configure_httr_pki(password = "my_pki_passphrase") # will not prompt for pki passphrase
GET("https://your.pki.enabled.website/path/to/whatever")
```
### Manual Configuration
#### Interactive Sessions
Configuration options can be defined explicitly to overwrite previous settings.
```r
library(rpki)
configure_httr_pki(mypki_file = "/path/to/new/pki/file",
                   ca_bundle = "/path/to/certificate_authority.crt",
                   pki_file  = "/path/to/my/pki.p12",
                   overwrite = TRUE)
GET('https://your.pki.enabled.website/path/to/whatever')
```
#### Non-interactive Sessions
rpki can run in non-interactive sessions as well when the pki passphrase is explicitly provided.
```r
library(rpki)
configure_httr_pki(mypki_file = "/path/to/new/pki/file",
                   ca_bundle = "/path/to/certificate_authority.crt",
                   pki_file  = "/path/to/my/pki.p12",
                   password  = "my_pki_passphrase",
                   overwrite = TRUE)
GET('https://your.pki.enabled.website/path/to/whatever')
```
