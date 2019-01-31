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

# per year
papersDT[,year:={
  y <- stringr::str_extract(PubDate,"[0-9]{4}")
  factor(y, levels = 2008:2018)
}][,Citations:=as.integer(PmcRefCount)][
  ,AvgCitationYear:=mean(Citations),year]
cbPalette <- c("#E69F00", "#00bf8b", "#CC79A7", "#56B4E9", "#F0E442", "#0072B2", "#D55E00", "#999999")
ggp_year <- ggplot(papersDT,aes(year)) + 
  geom_bar(aes(fill=PubType)) + 
  scale_x_discrete(limits=levels(papersDT)) +
  scale_fill_manual(name="Publication type:", breaks=papersDT, values=cbPalette)
maxy <- max(ggplot_build(ggp_year)[[1]][[1]][,"y"])
maxy2 <- max(papersDT)
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
    limits=c(0,max(papersDT)),expand=c(0,0)) +
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

