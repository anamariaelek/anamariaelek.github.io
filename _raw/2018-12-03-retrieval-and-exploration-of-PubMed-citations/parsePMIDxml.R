#!/usr/bin/env Rscript
if (!requireNamespace("xml2", quietly = TRUE))
    install.packages("xml2")
library(xml2)
args <- commandArgs(trailingOnly=TRUE)
# test if there is at least one argument
if (length(args)==0) {
  stop("The script a takes single argument, input file.n", call.=FALSE)
}
args[2] = "PMIDs.txt" # default output file
xmlinput <- read_xml(args[1])
ids <- xml_text(xml_find_all(xmlinput, "//Id"))
writeLines(ids, args[2])

