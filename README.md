# rpki
rpki is a wrapper package that PKI-enables the [httr](https://github.com/r-lib/httr) package and the built-in `download.file()` method. Conceptually, rpki is similar to the Python [pypki2](https://github.com/nbgallery/pypki2) and [ipydeps](https://github.com/nbgallery/ipydeps) packages, and is intended to use the same mypki configuration file.

## Installation
1. Download rpki from the git repository and unzip the folder. Rename the folder to `rpki` if necessary
2. Open a terminal and go to the directory where the `rpki` folder was downloaded
3. Run the command:
```code
R CMD INSTALL rpki
```

### Requirements
* R (>= 3.3.0)
* [curl](https://curl.haxx.se) - should be installed and executable from the command line (i.e. on the PATH)

## Details
rpki can run in interactive or non-interactive R sessions (depending on how the pki passphrase is provided). By default, rpki expects a .mypki configuration file to be located in a user's home directory at `~/.mypki`. If the configuration file is invalid or corrupt, the user will be prompted for file paths to a certificate authority bundle and a PKI file.

To pki-enable the httr package, the following httr config settings are defined
* cainfo
* sslcert
* sslkey
* keypasswd

To pki-enable the `download.file()` method, the download method is set to "curl" and the following extra curl command line arguments are set
* cacert
* cert
* key
* pass

rpki will only prompt the user for a pki passphrase once per R session.

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
pki_enable_httr() # will prompt for pki passphrase if necessary
GET('https://your.pki.enabled.website/path/to/whatever')
```
```r
library(rpki)
pki_enable_download_file() # will prompt for passphrase
install.packages('my_private_package')
```
### Non-interactive
rpki can run in non-interactive sessions when the pki passphrase is explicitly provided.
```r
library(rpki)
pki_enable_httr(password = 'my_pki_passphrase') # will not prompt for pki passphrase
GET('https://your.pki.enabled.website/path/to/whatever')
```
```r
library(rpki)
pki_enable_download_file(password = 'my_pki_passphrase')
install.packages('my_private_package')
```
### Manual Configuration
Configuration options can be explicitly defined in order to overwrite previous settings.
### Interactive Sessions
```r
library(rpki)
pki_enable_httr(mypki_file = '/path/to/new/pki/file',
                   ca_bundle = '/path/to/certificate_authority.crt',
                   pki_file  = '/path/to/my/pki.p12',
                   overwrite = TRUE)
GET('https://your.pki.enabled.website/path/to/whatever')
pki_enable_download_file() # will not prompt for password again
install.packages('my_private_package')
```
### Non-interactive Sessions
```r
library(rpki)
pki_enable_httr(mypki_file = '/path/to/new/pki/file',
                   ca_bundle = '/path/to/certificate_authority.crt',
                   pki_file  = '/path/to/my/pki.p12',
                   password  = 'my_pki_passphrase',
                   overwrite = TRUE)
GET('https://your.pki.enabled.website/path/to/whatever')
pki_enable_download_file() # will not prompt for password again
install.packages('my_private_package')
```
