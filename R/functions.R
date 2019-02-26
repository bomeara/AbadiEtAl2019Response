#' Get information about data set size
#'
#' Data set size, complexity, etc.
#'
#' @param dir The directory to pull in
#' @param maxtree How many of the available trees to pull in
#' @param treesearch Boolean on whether to tree search or not
#' @return A data.frame with info on each data set
#' @export
summarizeData <- function(dir="c3", maxtree=Inf, treesearch=TRUE) {
  files <- list.files(paste0("data/",dir), pattern="*phy")
  if(is.finite(maxtree)) {
    files <- files[1:maxtree]
  }
	result <- data.frame()
	for (file_index in seq_along(files)) {
		local_run <- NULL
		try(local_run <- runTree(paste0("data/",dir, "/", files[file_index])))
		if(!is.null(local_run)) {
			result <- plyr::rbind.fill(result, local_run)
			#save(result, file="docs/results.rda")
			#write.csv(result, file="docs/results.csv")
			#system("git commit -m'data caching' -a; git push")
		}

	}
	return(result)
}

#' Run individual step
#'
#' Gets phyml tree, bionj, etc.
#'
#' @param infile The file to pull in (include path)
#' @param treesearch Boolean on whether to tree search or not
#' @return data.frame of the trees and other info
#' @export
runTree <- function(infile, treesearch=TRUE) {
	dna <- ape::read.dna(file=infile)

  bionj_tree <- NA
  upgma_tree <- NA
  jc_tree <- NA
  gtr_ig_tree <- NA
  gtr_ig_tree_100 <- NA
  gtr_ig_tree_250 <- NA
  if(treesearch) {
  	dna_100 <- dna[,sample.int(n=ncol(dna), size=100, replace=TRUE)]
  	ape::write.dna(dna_100, file=paste0(infile, "_100"))
  	dna_250 <- dna[,sample.int(n=ncol(dna), size=250, replace=TRUE)]
  	ape::write.dna(dna_250, file=paste0(infile, "_250"))
  	bionj_tree <- ape::write.tree(ape::bionj(ape::dist.dna(dna)))
  	upgma_tree <- ape::write.tree(phangorn::upgma(dna))
  	jc_tree <- ape::write.tree(runPhyml(infile, model=" -m JC69 -f m"))
  	gtr_ig_tree <- ape::write.tree(runPhyml(infile, model=" -m GTR -f m -v e -a e"))
  	gtr_ig_tree_100 <- ape::write.tree(runPhyml(paste0(infile, "_100"), model=" -m GTR -f m -v e -a e"))
  	gtr_ig_tree_250 <- ape::write.tree(runPhyml(paste0(infile, "_250"), model=" -m GTR -f m -v e -a e"))
  }
	result <- data.frame(ntax=nrow(dna), nsites=ncol(dna), pars_inf_count=ips::pis(dna, what="absolute"), pars_inf_fraction=ips::pis(dna, what="fraction"), bionj=bionj_tree, upgma=upgma_tree, jc=jc_tree, gtrig=gtr_ig_tree, gtrig100 = gtr_ig_tree_100, gtrig250 = gtr_ig_tree_250)
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

#' Get OpenTree tree sizes
#'
#' Note we're getting just one tree per study
#'
#' @return data.frame with tree sizes
#' @export
otol_trees <- function() {
  all_trees <- rotl::studies_find_trees(property="is_deprecated", value="false")
  tree_ids <- all_trees$match_tree_ids
  only_first <- function(x) {
    return(strsplit(x, ",")[[1]][1])
  }
  for (i in seq_along(tree_ids)) {
    tree_ids[i] <- only_first(tree_ids[i])
  }
  tree_info <- data.frame(study_id = all_trees$study_ids, tree_id=tree_ids, ntax=NA, nnode=NA, stringsAsFactors=FALSE)
  for (i in seq_along(tree_ids)) {
    phy <- NULL
    try(phy <- rotl::get_study_tree(tree_info$study_id[i], tree_info$tree_id[i]))
    if(!is.null(phy)) {
      tree_info$ntax[i] <- ape::Ntip(phy)
      tree_info$nnode[i] <- ape::Nnode(phy)
    }
  }
  return(tree_info)
}
