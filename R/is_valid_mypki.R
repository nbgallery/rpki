# check for mypki file existence and check that the file
# has valid config parameters
#' @import openssl
is_valid_mypki <- function(file, password = NULL) {
  # verify mypki exist
  if (!file.exists(file)) {
    message(paste0(file, ' not found.'))
    return(FALSE)
  }

  # verify format of mypki file (json)
  json_data <- tryCatch(
    jsonlite::fromJSON(txt = file),
    error = function(e) {
      message(paste0('Malformed ', file, ' file.'))
      return(FALSE)
    }
  )

  # verify the Certificate Authority bundle
  if (!('ca' %in% names(json_data))) {
    message(paste0('Certifate Authority (CA) file not specified in ', file))
    return(FALSE)
  }
  if (!(file.exists(json_data$ca))) {
    message('Certifate Authority (CA) file not found.')
    return(FALSE)
  }
  if(length(read_cert_bundle(file = json_data$ca)) == 0) {
    message('Unrecognized Certifate Authority (CA) file format.')
    return(FALSE)
  }

  # verify the PKI certificate
  if (!('p12' %in% names(json_data) && "path" %in% names(json_data$p12))) {
    message(paste0('PKI file not specified in ', file))
    return(FALSE)
  }
  if (!file.exists(json_data$p12$path)) {
    message('PKI file not found.')
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
      message('Incorrect password format.')
    if (bad_password)
      return(FALSE)
  }
  TRUE
}
