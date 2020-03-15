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
  # remove pki certificate and key files
  if (!is.null(getOption("httr_config"))) {
    if (length(getOption("httr_config")$options) > 0) {
      result <- tryCatch({
        f <- c(
          getOption("httr_config")$options$sslcert,
          getOption("httr_config")$options$sslkey
        )
        file.remove(f)
      })
    }
  }
  # clean up the httr options that were set
  if (isNamespaceLoaded("httr")) httr::reset_config()
  options("httr_config" = NULL)
  # restore download.file settings to original values
  options("download.file.method" = getOption("rpki_backup_download.file.method"))
  options("download.file.extra" = getOption("rpki_backup_download.file.extra"))
  # remove pki password from memory
  options("rpki_password" = NULL)
}
