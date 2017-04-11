# retrieve the default path to a .mypki file
get_mypki_path <- function() {
  home_dir = ''
  # Get home directory in Windows
  if (.Platform$OS.type == 'windows') {
    home_dir = Sys.getenv('USERPROFILE')
    if (home_dir == '') warning('Could not find USERPROFILE environment variable.')
  }
  # Get home directory in Linux/Mac
  if (.Platform$OS.type == 'unix') {
    home_dir = Sys.getenv('HOME')
    if (home_dir == '') warning('Could not find HOME environment variable.')
  }
  if (home_dir == '') stop('Could not determine home directory.') # this should never happen
  path <- paste0(home_dir, .Platform$file.sep, '.mypki')
}
