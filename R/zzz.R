# backup R environment settings before package is used
.onLoad <- function(...) {
  options("rpki_backup_download.file.method" = getOption("download.file.method"))
  options("rpki_backup_download.file.extra" = getOption("download.file.extra"))
}

.onDetach <- function(...) {
  package_cleanup()
}

.onUnload <- function(...) {
  package_cleanup()
}

environment_cleanup <- function(e) {
  package_cleanup()
}

package_cleanup <- function() {
  # delete temporary pki certificate and key files
  if (!is.null(getOption("httr_config"))) {
    if (length(getOption("httr_config")$options) > 0) {
      f <- c(
        getOption("httr_config")$options$sslcert,
        getOption("httr_config")$options$sslkey
      )
      suppressWarnings(file.remove(f))
    }
  }
  # clean up the httr options that were set
  if (isNamespaceLoaded("httr")) httr::reset_config()
  options("httr_config" = NULL)
  # restore download.file settings to original values
  if (!is.null(getOption("rpki_backup_download.file.method"))) options("download.file.method" = getOption("rpki_backup_download.file.method"))
  if (!is.null(getOption("rpki_backup_download.file.extra"))) options("download.file.extra" = getOption("rpki_backup_download.file.extra"))
  # erase rpki settings from memory
  options("rpki_ca_file" = NULL)
  options("rpki_pki_file" = NULL)
  options("rpki_password" = NULL)
}
