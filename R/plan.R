report <- drake_plan(
  data_summary = summarizeData(maxtree=5),
  tree_summary = treetree(data_summary),
  report = knitr::knit(drake::knitr_in("docs/index.Rmd"), drake::file_out("docs/index.md"), quiet = TRUE),
  pdf_report = render_pdf("index.md", "index.pdf", "docs", report)
)
