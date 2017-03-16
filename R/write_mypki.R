
write_mypki <- function(mypki_file, ca_file, pki_file) {
  # write file paths to mypki file
  x <- list(ca=ca_file, p12=list(path=pki_file))
  write(jsonlite::toJSON(x), file=mypki_file)
}
