report <- drake_plan(
  report = knit(knitr_in("docs/index.Rmd"), file_out("docs/index.md"), quiet = TRUE),
  pdf_report = render_pdf("index.md", "index.pdf", "docs", report)
)
