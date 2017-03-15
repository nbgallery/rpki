# get user input and create a mypki formatted file
create_mypki <- function(file_path) {

  # repeatedly ask for CA file and P12 file until they have been entered and verified
  repeat{
    # ask for file paths and verify file existence
    ca.file <- readline(prompt="Enter full path to Certificate Authority bundle (.crt): ")
    pki.file <- readline(prompt="Enter full path to your PKI certificate file: ")

    # write file paths to mypki file
    x <- list(ca=ca.file, p12=list(path=pki.file))
    write(jsonlite::toJSON(x), file=file_path)

    # check that mypki file is valid (i.e. correct file paths, etc.)
    if (is_valid_mypki(file_path))
      break
  }
}
