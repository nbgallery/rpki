# rpki
rpki is a wrapper package that PKI-enables the [httr](https://github.com/r-lib/httr) package and the built-in `download.file()` method. Conceptually, rpki is similar to the Python [pypki2](https://github.com/nbgallery/pypki2) and [ipydeps](https://github.com/nbgallery/ipydeps) packages, and is intended to use the same mypki configuration file.

## Installation
1. Download rpki from the git repository and unzip the folder. Rename the folder to `rpki` if necessary.
2. Open a terminal and go to the directory where the `rpki` folder was downloaded.
3. Run the command
```
R CMD INSTALL rpki
```

### Requirements
* R (>= 3.3.0)
* [curl](https://curl.haxx.se) - should be installed and executable from the command line (i.e. on the PATH)
* [openssl](https://www.openssl.org/) - should be installed and exucutable from the command line (i.e. on the PATH)

## Quickstart
At minimum, you must provide a pkcs#12 file (and password) and Certificate Authority bundle
```r
library(rpki)
pki_enable_httr(pki_file = '/path/to/my/pki_file.p12', ca_file = 'path/to/my/ca_bundle.crt')
GET('https://your.pki.enabled.website/path/to/whatever')
```

## Examples
rpki can run in interactive or non-interactive R sessions. The major difference is the pki passphrase must be passed in plain text for non-interactive sessions (see examples below). All examples below assume a mypki configuration file has been created (see section on .mypki configuration file).

### Interactive - Fetching a URL
```r
library(rpki)
pki_enable_httr() # will prompt for pki passphrase if necessary
GET('https://your.pki.enabled.website/path/to/whatever')
```
### Non-interactive - Fetching a URL
rpki can run in non-interactive sessions when the pki passphrase is explicitly provided.
```r
library(rpki)
pki_enable_httr(password = 'my_pki_passphrase') # will not prompt for pki passphrase
GET('https://your.pki.enabled.website/path/to/whatever')
```

### Interactive - Installing a package
```r
library(rpki)
pki_enable_download_file() # will prompt for passphrase
install.packages('my_private_package')
```
### Non-interactive - Installing a package
```r
library(rpki)
pki_enable_download_file(password = 'my_pki_passphrase')
install.packages('my_private_package')
```

## Manual Configuration
Configuration options can be explicitly defined in order to overwrite default settings (interactive or non-interactive mode).
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

## Details
By default rpki expects a .mypki configuration file to be located in the user's home directory at `~/.mypki`. If the configuration file is invalid or corrupt, the user will be prompted for file paths to a certificate authority bundle and a PKI file.

To pki-enable the httr package, rpki modifies the following httr config settings
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
A proper .mypki configuration file should be json formatted and at minimum specify the absolute file paths to a Certificate Authority (CA) bundle and a pkcs#12 digital certificate.
```json
{
  "ca": "/path/to/certificate_authority_bundle.crt",
  "p12": {
    "path": "/path/to/pki_digital_certificate.p12"
  }
}
```
