create_mypki <- function(file_path) {
  repeat{
    ca_file <- readline(prompt = 'Enter full path to Certificate Authority bundle (.crt): ')
    pki_file <- readline(prompt = 'Enter full path to your PKI certificate file: ')

    write_mypki(file_path, ca_file, pki_file)
    # check that mypki file is valid (i.e. correct file paths, etc.)
    if (is_valid_mypki(file_path))
      break
  }
}
