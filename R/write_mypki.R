write_mypki <- function(mypki_file, ca_file, pki_file) {
  l <- list(ca = ca_file, p12 = list(path = pki_file))
  write(jsonlite::toJSON(l, pretty = TRUE, auto_unbox = TRUE), file = mypki_file)
}
