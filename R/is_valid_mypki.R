# check for mypki file existence and check that the file
# has valid config parameters
is_valid_mypki <- function(path) {
  # check that mypki file exists
  if (!file.exists(path)) {
    warning(paste0(path, ' not found.'))
    return(FALSE)
  }

  # verify format (json) of mypki file
  json_data <- tryCatch(
    jsonlite::fromJSON(txt = path),
    error = function(e) {
      # json file format is messed up
      warning(paste0('Malformed ', path, ' file.'))
      return(FALSE)
    }
  )

  # verify the Certificate Authority file path
  # that is expected to be in mypki file
  if (!('ca' %in% names(json_data))) {
    warning('File path for Certifate Authority (CA) bundle not specified')
    return(FALSE)
  }
  if (!(file.exists(json_data$ca))) {
    warning('Certifate Authority (CA) bundle file not found')
    return(FALSE)
  }
  if (!tools::file_ext(json_data$ca) == 'crt') {
    warning('Certificate Authority bundle must have .crt file extension. Do you have the right file format?')
    return(FALSE)
  }

  # verify the P12 PKI file path that is expected to be in mypki file
  if (!('p12' %in% names(json_data) && "path" %in% names(json_data$p12))) {
    warning('File path for PKI certificate not specified')
    return(FALSE)
  }
  if (!file.exists(json_data$p12$path)) {
    warning('PKI file not found')
    return(FALSE)
  }
  if (!tools::file_ext(json_data$p12$path) %in% c('p12','pfx')) {
    warning('PKI certificate must be in p12 format.')
    return(FALSE)
  }
  TRUE
}
