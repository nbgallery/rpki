# construct a legitimate path to the .mypki file
get_config_path <- function() {
  if (Sys.getenv("HOME") == "")
    stop("Could not find HOME environment variable.")

  path = paste0(Sys.getenv("HOME"), .Platform$file.sep, ".mypki")
  return(path)
}
