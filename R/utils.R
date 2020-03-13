# check for external software dependencies
dependency_check <- function() {
  prog <- Sys.which('openssl')
  if(!file.exists(prog))
    stop('ERROR: Unable to locate openssl executable. Openssl is not installed or not on the search path.')
  prog <- Sys.which('curl')
  if(!file.exists(prog))
    stop('ERROR: Unable to locate curl executable. Curl is not installed or not on the search path.')
}

# write a json-formatted .mypki file
write_mypki <- function(mypki_file, ca_file, pki_file) {
  l <- list(ca = ca_file, p12 = list(path = pki_file))
  write(jsonlite::toJSON(l, pretty = TRUE, auto_unbox = TRUE), file = mypki_file)
}

mypki_config_path <- function() {
  d = Sys.getenv('MYPKI_CONFIG')
  if(dir.exists(d)) {
    paste0(d, .Platform$file.sep, 'mypki_config')
  } else return(NULL)
}

home_config_path <- function() {
  d = Sys.getenv('HOME')
  if(dir.exists(d)) {
    return(paste0(d, .Platform$file.sep, '.mypki'))
  } else
    return(NULL)
}

# get default .mypki file path
get_config_path <- function() {
  p <- mypki_config_path()
  if(!is.null(p))
    return(p)

  p <- home_config_path()
  if(!is.null(p))
    return(p)

  warning('Could not find MYPKI_CONFIG or HOME environment variables. If you are on Windows, you need to add a MYPKI_CONFIG environment variable in the Control Panel.')
}

# create a new .mypki file in JSON format at the specified file location
create_mypki <- function(file) {
  max_tries <- 10 # prevent an infinite loop situation
  try <- 0
  repeat{
    ca_file <- readline(prompt = 'Enter full file path to Certificate Authority bundle (.crt): ')
    ca_file <- stringr::str_trim(ca_file)
    pki_file <- readline(prompt = 'Enter full file path to PKI certificate file: ')
    pki_file <- stringr::str_trim(pki_file)

    write_mypki(mypki_file = file, ca_file = ca_file, pki_file = pki_file)
    if (is_valid_mypki(file = file))
      return(TRUE)

    try <- try + 1
    if (try >= max_tries) {
      file.remove(file)
      stop('Max number of attempts made. Exiting.')
    }
  }
  message(paste0('Created .mypki file at ', file))
}


# check for .mypki file existence and verify the file
# has valid configuration parameters
is_valid_mypki <- function(file, password = NULL) {
  # check .mypki file path
  if (!file.exists(file)) {
    message(paste0(file, ' not found.'))
    return(FALSE)
  }

  # check .mypki file format (json)
  json_data <- tryCatch(
    jsonlite::fromJSON(txt = file),
    error = function(e) {
      message(paste0('Unable to parse mypki file at ', file, '. Is it in json format?'))
      return(FALSE)
    }
  )

  # check that a Certificate Authority bundle is specified in the .mypki file
  if (!('ca' %in% names(json_data))) {
    message(paste0('Certifate Authority (CA) file not specified in ', file))
    return(FALSE)
  }

  # check file path of Certificate Authority bundle
  if (!(file.exists(json_data$ca))) {
    message(paste0('Cannot find Certifate Authority (CA) file. Expected at ', json_data$ca))
    return(FALSE)
  }

  # check file format of Certificate Authority bundle
  if(length(read_cert_bundle(file = json_data$ca)) == 0) {
    message('Unrecognized Certifate Authority (CA) file format.')
    return(FALSE)
  }

  # check that a pki certificate is specified in the .mypki file
  if (!('p12' %in% names(json_data) && "path" %in% names(json_data$p12))) {
    message(paste0('PKI file not specified in ', file))
    return(FALSE)
  }

  # check file path of pki certificate
  if (!file.exists(json_data$p12$path)) {
    message(paste0('PKI file not found. Expected at ',json_data$p12$path))
    return(FALSE)
  }

  # check file format and verify pki password
  if (!is.null(password)) {
    bad_password = TRUE
    if ((typeof(password) == 'character') & (nchar(password) > 0)) {
      tryCatch({
        openssl::read_p12(file = json_data$p12$path, password = password)
        bad_password = FALSE
      },
      error = function(e) message('Incorrect password.')
      )
    } else
      message('Incorrect password format.')
    if (bad_password)
      return(FALSE)
  }
  TRUE
}

# input: file path to a pkcs#12 file
get_pki_cert <- function(pki_file, password) {
  cert_file <- getOption('rpki_cert')
  if(!is.null(cert_file))
    return(cert_file)

  # wrap password and pki filename in quotes in case white space or special characters exist
  password <- shQuote(password)
  pki_file <- shQuote(pki_file)

  # extract certificate and write to a temporary file
  cert_file <- tempfile()
  p12 <- openssl::read_p12(file=pki_file, password=password)
  openssl::write_pem(p12$cert, path=cert_file)

  options('rpki_cert' = cert_file)
  return(cert_file)
}

get_pki_key <- function(pki_file, password) {
  key_file <- getOption('rpki_key')
  if(!is.null(key_file))
    return(key_file)

  # wrap password and pki filename in quotes in case of
  # white space or special characters exist
  password <- shQuote(password)
  pki_file <- shQuote(pki_file)

  # convert pki to pem format and
  # create encrypted RSA key file in PKCS#1 format
  key_file <- tempfile()
  p12 <- openssl::read_p12(file=pki_file, password=password)
  openssl::write_pkcs1(p12$key, path=key_file, password=password)

  options('rpki_key' = key_file)
  return(key_file)
}

# Ask for pki password and store it for reuse during the current session
get_pki_password <- function() {
  p <- getOption('rpki_password')
  if(is.null(p)) {
    p <- getPass::getPass('Enter PKI Password: ')
    options('rpki_password' = p)
  }
  return(p)
}
