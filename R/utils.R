# write a json-formatted .mypki file
write_mypki <- function(mypki_file, ca_file, pki_file) {
  l <- list(ca = ca_file, p12 = list(path = pki_file))
  write(jsonlite::toJSON(l, pretty = TRUE, auto_unbox = TRUE), file = mypki_file)
}


# get default .mypki file path
# default = user home directory
get_mypki_path <- function() {
  home_dir = ''
  # Windows
  if (.Platform$OS.type == 'windows') {
    home_dir = Sys.getenv('USERPROFILE')
    if (home_dir == '') warning('Could not find USERPROFILE environment variable.')
  }
  # Linux/Mac
  if (.Platform$OS.type == 'unix') {
    home_dir = Sys.getenv('HOME')
    if (home_dir == '') warning('Could not find HOME environment variable.')
  }
  if (home_dir == '') stop('Could not determine home directory.') # this should never happen
  path <- paste0(home_dir, .Platform$file.sep, '.mypki')
}


# create a new .mypki file at the specified file location
create_mypki <- function(file) {
  max_tries <- 10 # prevent an infinite loop situation
  try <- 0
  repeat{
    ca_file <- readline(prompt = 'Enter full path to Certificate Authority bundle (.crt): ')
    ca_file <- stringr::str_trim(ca_file)
    pki_file <- readline(prompt = 'Enter full path to PKI certificate file: ')
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
      message(paste0('Malformed ', file, ' file.'))
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
    message('Certifate Authority (CA) file not found.')
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
    message('PKI file not found.')
    return(FALSE)
  }

  # check file format and verify pki passphrase of pki certificate
  if (!is.null(password)) {
    bad_password = TRUE
    if ((typeof(password) == 'character') & (length(password) ==1)) {
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

get_pki_cert <- function(pki) {
  cert <- getOption('rpki_cert')
  if (is.null(cert)) {
    pass <- getOption('rpki_passphrase')

    cert <- tempfile()
    system2('openssl', args = c('pkcs12',
                              '-in', pki,
                              '-out', cert,
                              '-clcerts', '-nokeys', '-nomacver',
                              '-passin', paste0('pass:', pass)),
          stdout = NULL,
          stderr = NULL)
    options('rpki_cert' = cert)
  }
  return(cert)
}

get_pki_key <- function(pki) {
  rsa_key <- getOption('rpki_key')
  if (is.null(rsa_key)) {
    pass <- getOption('rpki_passphrase')

    # convert pki to pem format (encrypted)
    tmp_key <- tempfile()
    system2('openssl', args = c('pkcs12',
                                '-in', pki,
                                '-out', tmp_key,
                                '-nocerts', '-nomacver',
                                '-passin', paste0('pass:', pass),
                                '-passout', paste0('pass:', pass)),
            stdout = NULL,
            stderr = NULL)

    # create encrypted RSA key file in PKCS#1 format
    rsa_key <- tempfile()
    system2('openssl', args = c('rsa',
                                '-in', tmp_key,
                                '-out', rsa_key,
                                '-des',
                                '-passin', paste0('pass:', pass),
                                '-passout', paste0('pass:', pass)),
            stdout = NULL,
            stderr = NULL)
    options('rpki_key' = rsa_key)
  }
  return(rsa_key)
}
