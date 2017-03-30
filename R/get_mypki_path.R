# default path to a .mypki file
get_mypki_path <- function() {
  if (Sys.getenv('HOME') == '')
    stop('Could not find HOME environment variable.')
  path <- paste0(Sys.getenv('HOME'), .Platform$file.sep, '.mypki')
}
