# rpki
rpki is a wrapper package that PKI-enables the httr package. Conceptually, rpki is similar to the Ruby [MyPKI](https://github.com/nbgallery/mypki) package and Python [pypki2](https://github.com/nbgallery/pypki2) package, and is intended to use the same mypki configuration file.

## Details
rpki can run in interactive or non-interactive R sessions (depending on how the pki passphrase is provided). By default, rpki expects a .mypki configuration file to be located at `~/.mypki`. If the configuration file is invalid or not found (wrong format, nonexistent file paths, .etc), the user will be prompted for file paths to a certificate authority bundle and a PKI file. rpki sets the following httr config settings
* cainfo
* sslcert
* sslkey
* keypasswd

### .mypki Configuration File
A proper .mypki configuration file should be json formatted and at minimum specify the absolute file paths to a Certificate Authority (CA) bundle and a PKCS12 digital certificate.
```json
{
  "ca": "/path/to/certificate_authority_bundle.crt",
  "p12": {
    "path": "/path/to/pki_digital_certificate.p12"
  }
}
```

## Examples - Fetching a URL
### Interactive
```r
library(rpki)
configure_httr_pki() # will prompt for pki passphrase if necessary
GET("https://your.pki.enabled.website/path/to/whatever")
```
### Non-interactive
rpki can run in non-interactive sessions when the pki passphrase is explicitly provided.
```r
library(rpki)
configure_httr_pki(password = "my_pki_passphrase") # will not prompt for pki passphrase
GET("https://your.pki.enabled.website/path/to/whatever")
```
### Manual Configuration
Configuration options can be explicitly defined in order to overwrite previous settings.
### Interactive Sessions
```r
library(rpki)
configure_httr_pki(mypki_file = "/path/to/new/pki/file",
                   ca_bundle = "/path/to/certificate_authority.crt",
                   pki_file  = "/path/to/my/pki.p12",
                   overwrite = TRUE)
GET('https://your.pki.enabled.website/path/to/whatever')
```
### Non-interactive Sessions
```r
library(rpki)
configure_httr_pki(mypki_file = "/path/to/new/pki/file",
                   ca_bundle = "/path/to/certificate_authority.crt",
                   pki_file  = "/path/to/my/pki.p12",
                   password  = "my_pki_passphrase",
                   overwrite = TRUE)
GET('https://your.pki.enabled.website/path/to/whatever')
```
