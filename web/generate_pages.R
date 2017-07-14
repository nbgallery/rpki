library(miniCRAN)
library(rmarkdown)

pkgs <- as.data.frame(pkgAvail(repos='/path/to/repo'))
# in a single for loop
#  1. define subgroup
#  2. render output
for (pkg in pkgs$Package) {
  env <- new.env()
  env$package_name <- pkg
  render(input="package_template.rmd",
         output_format="html_document",
         output_file=paste0(pkg, '_report', '.html'),
         envir = env,
         quiet=TRUE)
}
