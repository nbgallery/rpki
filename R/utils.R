# check for external software dependencies
dependency_check <- function() {
  if (!nzchar(Sys.which("curl"))) {
    stop("ERROR: Unable to locate curl executable. Curl is not installed or not on the search path.")
  }
}

# write a json-formatted .mypki file
write_mypki <- function(mypki_file, ca_file, pki_file) {
  l <- list(ca = ca_file, p12 = list(path = pki_file))
  write(jsonlite::toJSON(l, pretty = TRUE, auto_unbox = TRUE), file = mypki_file)
}

# return filepath to a .mypki file
get_config_path <- function() {
  # check for MYPKI_CONFIG environment variable
  d <- Sys.getenv("MYPKI_CONFIG")
  if (dir.exists(d)) {
    return(paste0(normalizePath(d), .Platform$file.sep, "mypki_config"))
  }

  # check for HOME environment variable
  d <- Sys.getenv("HOME")
  if (dir.exists(d)) {
    return(paste0(normalizePath(d), .Platform$file.sep, ".mypki"))
  }

  stop("Could not find MYPKI_CONFIG or HOME environment variables.")
}

# check for .mypki file existence and verify the file
# has valid configuration parameters
is_valid_mypki <- function(file) {
  # check .mypki file path
  if (!file.exists(file)) {
    message(paste0(file, " not found."))
    return(FALSE)
  }

  # check .mypki file format (json)
  json_data <- tryCatch(
    jsonlite::fromJSON(txt = file),
    error = function(e) {
      message(paste0("Unable to parse mypki file at ", file, ". Is it in json format?"))
      return(FALSE)
    }
  )

  # check if Certificate Authority bundle is declared in the mypki file
  if (!("ca" %in% names(json_data))) {
    message(paste0("Certifate Authority (CA) file not specified in ", file))
    return(FALSE)
  }

  # check file existence of Certificate Authority bundle
  if (!(file.exists(json_data$ca))) {
    message(paste0("Cannot find Certifate Authority (CA) file. Expected at ", json_data$ca))
    return(FALSE)
  }

  # check file format of Certificate Authority bundle
  if (length(openssl::read_cert_bundle(file = json_data$ca)) == 0) {
    message("Unrecognized Certifate Authority (CA) file format.")
    return(FALSE)
  }

  # check if pki certificate is declared in the mypki file
  if (!("p12" %in% names(json_data) && "path" %in% names(json_data$p12))) {
    message(paste0("PKI file not specified in ", file))
    return(FALSE)
  }

  # check file existence of pki certificate
  if (!file.exists(json_data$p12$path)) {
    message(paste0("PKI file not found. Expected at ", json_data$p12$path))
    return(FALSE)
  }

  # check file format and verify pki password
  passwd <- get_pki_password()
  if (!is.null(passwd)) {
    # check type conversion of passwd
    if ((typeof(passwd) != "character") || (nchar(passwd) == 0)) {
      package_cleanup()
      stop("Incorrect password format.")
    }
    # try to unencrypt file with password
    unlocked_p12 <- tryCatch(
      {
        openssl::read_p12(file = json_data$p12$path, password = passwd)
      },
      error = function(err) {
        package_cleanup()
        stop("Incorrect password.")
      }
    )
  } else {
    warning("pki password not available")
  }

  return(TRUE)
}

# primary function that constructs a mypki file
# will prompt the the user for input if necessary
configure_mypki <- function(pki_file = NULL, ca_file = NULL, password = NULL, override = FALSE) {
  # determine mypki file location
  mypki_file <- get_config_path() # defaults to home directory

  # override all settings?
  if (override) {
    # delete prior mypki settings if they exist
    package_cleanup()
    try(file.remove(mypki_file), silent = TRUE)
  }

  # is pki_file defined?
  if (is.null(pki_file) && !is.null(getOption("rpki_pki_file"))) {
    pki_file <- getOption("rpki_pki_file")
  }
  if (is.null(pki_file)) {
    pki_file <- readline(prompt = "Enter filepath to PKI certificate file: ")
  }
  pki_file <- normalizePath(pki_file)

  # is ca_file defined?
  if (is.null(ca_file) && !is.null(getOption("rpki_ca_file"))) {
    ca_file <- getOption("rpki_ca_file")
  }
  if (is.null(ca_file)) {
    ca_file <- readline(prompt = "Enter filepath to Certificate Authority bundle (.crt): ")
  }
  ca_file <- normalizePath(ca_file)

  # is password defined?
  if (!is.null(password)) set_pki_password(password)
  # otherwise get pki password from user
  p <- get_pki_password()

  # write mypki settings out to a file
  write_mypki(mypki_file = mypki_file, ca_file = ca_file, pki_file = pki_file)

  # read from existing mypki file
  valid <- is_valid_mypki(file = mypki_file)
  if (!valid) {
    stop(paste0("Invalid mypki configuration file at: ", mypki_file))
  }

  # save filepaths to reuse later in the same session (they have now been verified)
  options("rpki_pki_file" = pki_file)
  options("rpki_ca_file" = ca_file)

  return(mypki_file)
}

# input: filepath to a pkcs#12 file
get_pki_cert <- function(pki_file) {
  cert_file <- getOption("rpki_cert")
  if (!is.null(cert_file)) {
    if (file.exists(cert_file)) {
      return(cert_file)
    }
  }
  password <- get_pki_password()
  # extract certificate and write to a temporary file
  cert_file <- tempfile()
  p12 <- openssl::read_p12(file = pki_file, password = password)
  openssl::write_pem(p12$cert, path = cert_file)
  options("rpki_cert" = cert_file)
  return(cert_file)
}

# input: filepath to a pkcs#12 file
get_pki_key <- function(pki_file) {
  key_file <- getOption("rpki_key")
  if (!is.null(key_file)) {
    if (file.exists(key_file)) {
      return(key_file)
    }
  }
  password <- get_pki_password()
  # convert pki to pem format and create encrypted RSA key file in PKCS#1 format
  key_file <- tempfile()
  p12 <- openssl::read_p12(file = pki_file, password = password)
  openssl::write_pkcs1(p12$key, path = key_file, password = password)
  options("rpki_key" = key_file)
  return(key_file)
}

# Ask for pki password and store for reuse during the current session
get_pki_password <- function(force = FALSE) {
  p <- getOption("rpki_password")
  if (any(is.null(p), force)) {
    p <- getPass::getPass("Enter PKI Password: ")
    options("rpki_password" = p)
  }
  return(p)
}

# Set pki password store it for reuse during the current session
set_pki_password <- function(passwd) {
  options("rpki_password" = passwd)
}
