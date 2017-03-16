# rpki
The aim of rpki is to provide a wrapper for the httr package to make it easier to access PKI-enabled services with R. Conceptually, rpki is similar to the Ruby [MyPKI](https://github.com/nbgallery/mypki) package and Python [pypki2](https://github.com/nbgallery/pypki2) package, and is intended to use the same ~/.mypki configuration file.

## Details
When rpki is first loaded via `library(rpki)`, the default behavior is to override the config() settings of httr to use the PKI configuration found in ~/.mypki. It will attempt to search for and use a pre-existing .mypki configuration file. If the configuration file is not found or is invalid, the user will be prompted for file paths to a certificate authority bundle and a PKI file. rpki sets the following httr config settings
* cainfo
* sslcert
* sslkey

## Examples
### Fetching a URL
```r
library(rpki)
GET("https://your.pki.enabled.website/path/to/whatever")
```
### Manually setting configuration options
In cases where automatic configuration is not desired, parameters can be set explicitly.
```r
rpki::set_pki_config(ca_bundle="/path/to/certificate_authority.crt",
                     p12_file="/path/to/my/pki.p12",
                     password="my_pki_passphrase")
GET('https://your.pki.enabled.website/path/to/whatever')
```
Note that executing the line `library(rpki)` triggers the automatic configuration process. For manual configuration, do **not** attach the package.
