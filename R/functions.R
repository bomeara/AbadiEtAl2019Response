#' Get information about data set size
#'
#' Data set size, complexity, etc.
#'
#' @param dir The directory to pull in
#' @return A data.frame with info on each data set
#' @export
summarizeData <- function(dir="c3", maxtree=Inf) {
  files <- list.files(paste0("data/",dir), pattern="*phy")[1:maxtree]
	result <- data.frame()
	for (file_index in seq_along(files)) {
		local_run <- NULL
		try(local_run <- runTree(paste0("data/",dir, "/", files[file_index])))
		if(!is.null(local_run)) {
			result <- plyr::rbind.fill(result, local_run)
			save(result, file="docs/results.rda")
			write.csv(result, file="docs/results.csv")
			system("git commit -m'data caching' -a; git push")
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
	dna_100 <- dna[,sample.int(n=ncol(dna), size=100, replace=TRUE)]
	ape::write.dna(dna_100, file=paste0(infile, "_100"))
	dna_250 <- dna[,sample.int(n=ncol(dna), size=250, replace=TRUE)]
	ape::write.dna(dna_250, file=paste0(infile, "_250"))
	bionj_tree <- ape::bionj(ape::dist.dna(dna))
	upgma_tree <- phangorn::upgma(dna)
	jc_tree <- runPhyml(infile, model=" -m JC69 -f m")
	gtr_ig_tree <- runPhyml(infile, model=" -m GTR -f m -v e -a e")
	gtr_ig_tree_100 <- runPhyml(paste0(infile, "_100"), model=" -m GTR -f m -v e -a e")
	gtr_ig_tree_250 <- runPhyml(paste0(infile, "_250"), model=" -m GTR -f m -v e -a e")
	result <- data.frame(ntax=nrow(dna), nsites=ncol(dna), pars_inf_count=ips::pis(dna, what="absolute"), pars_inf_fraction=ips::pis(dna, what="fraction"), bionj=ape::write.tree(bionj_tree), upgma=ape::write.tree(upgma_tree), jc=ape::write.tree(jc_tree), gtrig=ape::write.tree(gtr_ig_tree), gtrig100 = ape::write.tree(gtr_ig_tree_100), gtrig250 = ape::write.tree(gtr_ig_tree_250))
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

#' Get tree-tree distances
#'
#' @param treeSummary Output from summarizeData
#' @return data.frame with tree-tree distances
#' @export
treetree <- function(treeSummary) {
  result <- treeSummary
  treeSummary$g_b <- NA
  treeSummary$g_u <- NA
  treeSummary$g_jc <- NA
  treeSummary$g_g100 <- NA
  treeSummary$g_g250 <- NA
  for (i in sequence(nrow(treeSummary))) {
    gtrig_tree <- ape::read.tree(text=treeSummary$gtrig[i])
    try(treeSummary$g_b[i] <- phangorn::RF.dist(gtrig_tree, ape::read.tree(text=treeSummary$bionj[i])))
    try(treeSummary$g_u[i] <- phangorn::RF.dist(gtrig_tree, ape::read.tree(text=treeSummary$upgma[i])))
    try(treeSummary$g_jc[i] <- phangorn::RF.dist(gtrig_tree, ape::read.tree(text=treeSummary$jc[i])))
    try(treeSummary$g_g100[i] <- phangorn::RF.dist(gtrig_tree, ape::read.tree(text=treeSummary$gtrig100[i])))
    try(treeSummary$g_g250[i] <- phangorn::RF.dist(gtrig_tree, ape::read.tree(text=treeSummary$gtr_ig_tree_250[i])))
  }
  return(treeSummary)
}
