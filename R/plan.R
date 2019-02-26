report <- drake_plan(
  c3_summary = summarizeData(maxtree=250),
  c3_tree_summary = treetree(c3_summary),
  empirical_summary = summarizeData(dir="empirical", treesearch=FALSE),
  otol_summary = otol_trees(),
  report = knitr::knit(drake::knitr_in("docs/index.Rmd"), drake::file_out("docs/index.md"), quiet = TRUE),
  pdf_report = render_pdf("index.md", "index.pdf", "docs", report),
  commit_and_push_result = commit_and_push(pdf_report, report)
)
