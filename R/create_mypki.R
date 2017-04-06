create_mypki <- function(file_path) {
  max_tries <- 10 # prevent an infinite loop situation
  try <- 0
  repeat{
    ca_file <- readline(prompt = 'Enter full path to Certificate Authority bundle (.crt): ')
    ca_file <- stringr::str_trim(ca_file)
    pki_file <- readline(prompt = 'Enter full path to PKI certificate file: ')
    pki_file <- stringr::str_trim(pki_file)

    if (ca_file == '' & pki_file == '')
      return( FALSE )

    write_mypki(file_path, ca_file, pki_file)
    if (is_valid_mypki(file_path))
      return( TRUE )

    try <- try + 1
    if (try >= max_tries) {
      warning('Max number of attempts made. Consider using set_pki_config()')
      file.remove(file_path)
      return( FALSE )
    }
  }
}
