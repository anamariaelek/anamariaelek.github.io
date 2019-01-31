#!/bin/bash

# find interesting articles PMIDs
db='pubmed'
query='Metagenome[mesh]+AND+Gastrointestinal+Microbiome[mesh]+AND+2008:2018[pdat]+AND+Journal+Article[ptyp]'
base='https://eutils.ncbi.nlm.nih.gov/entrez/eutils/'
url=$base"esearch.fcgi?db=$db&term=$query&retmax=100000"
curl $url -g -o esearch_pmid.xml

# save list of PMIDs to a text file
cat >> parsePMIDxml.R << EOF
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

EOF
Rscript --vanilla parsePMIDxml.R esearch_pmid.xml

# find summary for interesting articles
url_search=$base"esearch.fcgi?db=$db&term=$query&usehistory=y"
curl $url_search -g -o esearch.xml
web=$(sed '3q;d' esearch.xml | sed -E 's/.*<WebEnv>([^<]+)<\/WebEnv>.*/\1/')
key=$(sed '3q;d' esearch.xml | sed -E 's/.*<QueryKey>([^<]+)<\/QueryKey>.*/\1/')
url_summary=$base"esummary.fcgi?db=pubmed&query_key=$key&WebEnv=$web"
curl $url_summary -g -o esummary.xml

# find articles citing interesting articles
ids=$(sed ':a;N;$!ba;s/\n/\&id=/g' PMIDs.txt | tr -d '\r')
url_link_byid=$base"elink.fcgi?dbfrom=$db&linkname=pubmed_pubmed_citedin&id=$ids" 
curl $url_link_byid -o elink.byid.xml

# post-processing
cat >> processPMIDxml.R << EOF
#!/usr/bin/env Rscript
pkgs <- c("xml2","data.table","ggplot2","stringr")
for (i in pkgs){
  if (!requireNamespace(i, quietly = TRUE))
    install.packages(i)
}
library(xml2)
library(data.table)
library(ggplot2)
# load data
esearch <- read_xml("esearch_pmid.xml")
esummary <- read_xml("esummary.xml")
elink <- read_xml("elink.byid.xml")
# extract data
ids <- xml_text(xml_find_all(esearch, "//Id"))
paper_info <- lapply(xml_find_all(esummary, "//DocSum"), function(x) {
  # get summary items
  items <- xml_find_all(x, xpath=".//Item")
  # for each summary item, get item name
  attnames <- sapply(xml_attrs(items), function(ats) ats["Name"])
  # and item content
  atts <- xml_text(items)
  names(atts) <- attnames
  atts
})
names(paper_info) <- ids
infos <- Reduce(intersect, lapply(paper_info,names))
summary <- lapply(paper_info, function(x){
  data.table(init=NA)[,I(infos):=as.list(x[infos])][,init:=NULL]
})
papersDT <- rbindlist(summary,idcol="PMID")
fwrite(papersDT,"papersSummary.csv")
# per year
papersDT[,year:={
  y <- stringr::str_extract(PubDate,"[0-9]{4}")
  factor(y, levels = 2008:2018)
}][,Citations:=as.integer(PmcRefCount)][
  ,AvgCitationYear:=mean(Citations),year]
cbPalette <- c("#E69F00", "#00bf8b", "#CC79A7", "#56B4E9", "#F0E442", "#0072B2", "#D55E00", "#999999")
ggp_year <- ggplot(papersDT,aes(year)) + 
  geom_bar(aes(fill=PubType)) + 
  scale_x_discrete(limits=levels(papersDT$year)) +
  scale_fill_manual(name="Publication type:", breaks=papersDT$PubType, values=cbPalette)
maxy <- max(ggplot_build(ggp_year)[[1]][[1]][,"y"])
maxy2 <- max(papersDT$AvgCitationYear)
scaling <- round(maxy/maxy2)
ggp_year <- ggp_year +
  geom_line(aes(year,AvgCitationYear*scaling,colour=""),group=1,linetype=1) +
  geom_point(aes(year,AvgCitationYear*scaling,colour="")) +
  scale_color_discrete("Average PMC citations: ") +
  scale_y_continuous(
    name="papers\n",
    sec.axis=sec_axis(~./scaling,name="average PMC citations\n")) +
  theme_light() + theme(
    text=element_text(size=12),
    panel.grid=element_line(colour="lightgray", linetype=3),
    legend.box="vertical", legend.direction="horizontal", legend.position="bottom"
  )

# per journal
papersDT[,JournalN:=.N,FullJournalName][
  ,Journal:=factor(Source,levels=unique(.SD[order(-JournalN),Source]))][
    ,AvgCitationJournal:=mean(Citations),Source]
ggp_journal <- ggplot(papersDT[JournalN>1],aes(Journal,fill=AvgCitationJournal)) + 
  geom_bar() + 
  scale_fill_gradient(name="Average\nPMC\ncitations", low="#68c0f2", high="#00599e") +
  scale_y_continuous(
    name="papers\n",
    limits=c(0,max(papersDT$JournalN)),expand=c(0,0)) +
  theme_light() + theme(
    text = element_text(size=12),
    panel.grid = element_line(colour="lightgray", linetype=3),
    axis.text.x=element_text(angle=45,hjust=1)
  )
# save output to pdf
pdf("eutilplots.pdf", width=8,height=5)
ggp_year
ggp_journal
dev.off()

# citations
paper_citations <- lapply(xml_find_all(elink, "//LinkSet"), function(x) {
  xml_text(xml_find_all(xml_find_all(x, ".//Link"), xpath=".//Id"))
})
names(paper_citations) <- ids
# save citations for papers
# format: each line starting with '#' contains PMID for a paper, 
# and the line below contains PMIDs for all the papers citing it
tofile <- sapply(ids, function(x) paste0("#",x,"\n",sapply(paper_citations[x],paste,collapse=",")))
writeLines(tofile, "papersCitations.txt")
EOF

Rscript --vanilla processPMIDxml.R
