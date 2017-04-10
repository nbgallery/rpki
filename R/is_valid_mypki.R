# check for mypki file existence and check that the file
# has valid config parameters
#' @importFrom tools file_ext
#' @import openssl
is_valid_mypki <- function(path, password = NULL) {
  # verify mypki exist
  if (!file.exists(path)) {
    warning(paste0(path, ' not found.'))
    return(FALSE)
  }

  # verify format of mypki file (json)
  json_data <- tryCatch(
    jsonlite::fromJSON(txt = path),
    error = function(e) {
      warning(paste0('Malformed ', path, ' file.'))
      return(FALSE)
    }
  )

  # verify the Certificate Authority bundle
  if (!('ca' %in% names(json_data))) {
    warning('File path for Certifate Authority (CA) bundle not specified.')
    return(FALSE)
  }
  if (!(file.exists(json_data$ca))) {
    warning('Certifate Authority (CA) bundle file not found.')
    return(FALSE)
  }
  if(length(read_pem(file = json_data$ca)) == 0) {
    warning('Unrecognized Certifate Authority (CA) bundle file format.')
    return(FALSE)
  }

  # verify the PKI certificate
  if (!('p12' %in% names(json_data) && "path" %in% names(json_data$p12))) {
    warning('File path for PKI certificate not specified.')
    return(FALSE)
  }
  if (!file.exists(json_data$p12$path)) {
    warning('PKI file not found.')
    return(FALSE)
  }
  if (!is.null(password)) {
    bad_password = TRUE
    if ((typeof(password) == 'character') & (length(password) ==1)) {
      tryCatch({
        read_p12(file = json_data$p12$path, password = password)
          bad_password = FALSE
        },
        error = function(e) warning('Incorrect password.')
      )
    } else
      warning('Incorrect password format.')
    if (bad_password)
      return(FALSE)
  }
  TRUE
}
