create_mypki <- function(file) {
  message(paste0('Creating mypki file at ', file))
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
}
