write_mypki <- function(mypki_path, ca_path, pki_path) {
  # write file paths to mypki file
  l <- list(ca = ca_path, p12 = list(path = pki_path))
  write(jsonlite::toJSON(l, pretty = TRUE, auto_unbox = TRUE), file = mypki_path)
}
