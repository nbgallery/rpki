create_mypki <- function(file_path) {
  message(paste0('Creating mypki file at ', file_path))
  max_tries <- 10 # prevents an infinite loop situation
  try <- 0
  repeat{
    ca_file <- readline(prompt = 'Enter full path to Certificate Authority bundle (.crt): ')
    ca_file <- stringr::str_trim(ca_file)
    pki_file <- readline(prompt = 'Enter full path to PKI certificate file: ')
    pki_file <- stringr::str_trim(pki_file)

    write_mypki(file_path, ca_file, pki_file)
    if (is_valid_mypki(file_path))
      return(TRUE)

    try <- try + 1
    if (try >= max_tries) {
      file.remove(file_path)
      stop('Max number of attempts made. Exiting.')
    }
  }
}
