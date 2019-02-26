#' Get information about data set size
#'
#' Data set size, complexity, etc.
#'
#' @param dir The directory to pull in
#' @return A data.frame with info on each data set
#' @export
summarizeData <- function(dir="c3") {
  files <- list.files(paste0("data/",dir), pattern="*phy")
	result <- data.frame()
	for (file_index in seq_along(files)) {
		local_run <- NULL
		try(local_run <- runTree(paste0("data/",dir, "/", files[file_index])))
		if(!is.null(local_run)) {
			result <- plyr::rbind.fill(result, local_run)
			save(result, file="docs/results.rda")
		}

	}
	return(result)
}

#' Run individual step
#'
#' Gets phyml tree, bionj, etc.
#'
#' @param infile The file to pull in (include path)
#' @return data.frame of the trees and other info
#' @export
runTree <- function(infile) {
	dna <- ape::read.dna(file=infile)
	bionj_tree <- ape::bionj(ape::dist.dna(dna))
	upgma_tree <- phangorn::upgma(dna)
	jc_tree <- runPhyml(infile, model=" -m JC69 -f m")
	gtr_ig_tree <- runPhyml(infile, model=" -m GTR -f m -v e -a e")
	result <- data.frame(ntax=nrow(dna), nsites=ncol(dna), pars_inf_count=ips::pis(dna, what="absolute"), pars_inf_fraction=ips::pis(dna, what="fraction"), bionj=ape::write.tree(bionj_tree), upgma=ape::write.tree(upgma_tree), jc=ape::write.tree(jc_tree), gtrig=ape::write.tree(gtr_ig_tree))
	return(result)
}

#' Run PHYML model
#'
#' Run PHYML using a model
#'
#' Model:
#' JC: " -m JC69 -f m"
#' GTR+I+G: " -m GTR -f m -v e -a e"
#'
#' @param infile Path to file and file name
#' @param model Model settings for phyml
#' @return Inferred tree
#' @export
runPhyml <- function(infile, model=" -m JC69 -f m") {
	system(paste0("phyml -i ", infile, model))
	phy <- ape::read.tree(paste0(infile, '_phyml_tree.txt'))
	system(paste0("rm ", paste0(infile, '_phyml_tree.txt')))
	system(paste0("rm ", paste0(infile, '_phyml_stats.txt')))
	return(phy)
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
