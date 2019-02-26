#' Get information about data set size
#'
#' Data set size, complexity, etc.
#'
#' @param dir The directory to pull in
#' @return A data.frame with info on each data set
#' @export
summarizeData <- function(dir="c3") {
  files <- list.files(paste0("data/",dir), pattern="*phy")
}

#' Make a pdf using pandoc
#'
#' @param file_in Input file
#' @param file_out Output file
#' @param dir Where to put file
#' @param placeholder Just to absorb an argument so drake thinks there's a dependency
#' @return Nothing
#' @export
render_pdf <- function(file_in, file_out, dir, placeholder) {
	original.dir <- getwd()
	setwd(dir)
	system(paste0("pandoc ", file_in, " -o ", file_out))
	setwd(original.dir)
}
