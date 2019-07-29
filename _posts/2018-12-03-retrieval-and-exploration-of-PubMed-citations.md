---
title: Searching PubMed by Text and Citations
author: Anamaria Elek 
date: 2018-12-03
output: 
  html_document:
  keep_md: true
tags: [R, Bash, NCBI, Entrez, PubMed]
feature-img: "assets/img/2018-12-03-retrieval-and-exploration-of-PubMed-citations_files/pubmed.jpg"
---

NCBI offers a set of URL-based programming utilities for querying its Entrez databases. Among those are the API for text search of articles in PubMed, the service that retrievs summaries for entries in the NCBI databases, and the service for finding articles that cite any given article, identified by PMID or PMCID. I use these utilities to explore research papers on gut metagenomes published in the last ten years.  

# Entrez Programming Utilities (E-utilities)

There are nine server-side programs throug which one can easily query and access the data in NCBI's Entrez databases. Those described in this post are shown in bold.

* __ESearch__: Search a text query in a single Entrez database.  
* __ESummary__: Retrieve document summaries for each UID.  
* EFetch: Retrieve full records for each UID.  
* EPost: Upload a list of UIDs for later use.  
* __ELink__: Retrieve UIDs for related or linked records, or LinkOut URLs.  
* EInfo: Retrieve information and statistics about a single database.  
* ESpell: Retrieve spelling suggestions for a text query.  
* ECitMatch: Search PubMed for a series of citation strings.  
* EGQuery: Search a text query in all Entrez databases and return the number of results for the query in each database.

All of the nine utilities work in the same way --- they access the core search and retrieval engine of the Entrez system by sending an URL request to the E-utilities server, which then generates and outputs the response in form of the XML (optionally JSON) file.  The E-utilities use unique identifiers (UIDs) for both data input and output. Examples of UIDs for different Entrez databases include GI numbers for Nucleotide and Protein databases, Gene ID for Gene database, rs numbers for SNPs, PMIDs for PubMed, and PMCID for PubMed Central.  

# Example 1: Simple PubMed text search

As a simlple introducton, let's say I want to get PubMed IDs of all journal articles dealing with gut metagenome (as identified by the MeSH terms 'metagenomes' and 'gastrointestinal tract'), which were published in the last 10 years.

## ESearch

In order to to find paper PMIDs, I first construct an URL request to be passed to ESearch utility. The base part of the url is the same for all E-utilities, and is followed by different parameters --- utility name, database we want to query, input to be used, which can be either UIDs or text query, and other optional parameters.  


```bash
db='pubmed'
query='Metagenome[mesh]+AND+Gastrointestinal+Microbiome[mesh]+AND+2008:2018[pdat]+AND+Journal+Article[ptyp]'
base='https://eutils.ncbi.nlm.nih.gov/entrez/eutils/'
url=$base"esearch.fcgi?db=$db&term=$query&rettype=count"
curl $url -g
```
  
Here I retrieve the __count__ of the resulting PMIDs, and not the PMIDs themselves, by specifying `rettype=count`. I do this in order to see how many IDs I will get for my query, because by default, ESearch will only output the first 20 results (equivalent of the first page of results you get when querying NCBI databases through a web browser). This behaviour can be changed by specifying the `retmax` parameter in the URL.  
I use curl to post an URL request, and `-g` flag prevents curl from parsing `[]` in the url. I could save the output xml (using the `-o` flag) and parse it in R --- more on how to do this below --- but for now, I only wanted to look up the results' count, and set the value of `retmax` parameter to something greater than this, in order to retrieve all the resulting IDs.  
Otherwise, I could've simply specified the maximum possible value of this parameter, which is 100 000 for a single URL request, being fairly confident that there should be less than 100 000 research papers on gut metagenomes published over the last 10 years.  


```bash
url=$base"esearch.fcgi?db=$db&term=$query&retmax=500"
curl $url -g -o esearch_pmid.xml
```
  
## xml2

Now I use R package `xml2` to get the simple list of PMIDs from the resulting xml file.  
`xml_find_all()` finds all nodes with paper IDs, and `xml_text()` then coerces these to character strings. 


```r
require(xml2)
esearch <- read_xml("esearch_pmid.xml")
ids <- xml_text(xml_find_all(esearch, "//Id"))
str(ids)
```

```
##  chr [1:263] "30078113" "29934497" "29907938" "29762673" "29746643" ...
```

There were 263 research articles published on gut metagenomes over the last 10 years. All in all, not a very large number. Finally, I save their PMIDs in a plain text file.  


```r
writeLines(ids, "PMIDs.txt")
```

# Example 2: Summary and cited-by for the list of PubMed articles

Now I want to find not just the PMIDs, but also the summarising information, such as publication date, authors and journal, for papers on gut metagenomes published in the last ten years, as well as which papers are citing each of those input papers. To do this, I will combine ESearch, ESummary and ELink utilities in the single pipeline analysis.

## ESearch


```bash
db='pubmed'
query='Metagenome[mesh]+AND+Gastrointestinal+Microbiome[mesh]+AND+2008:2018[pdat]+AND+Journal+Article[ptyp]'
base='https://eutils.ncbi.nlm.nih.gov/entrez/eutils/'
url_search=$base"esearch.fcgi?db=$db&term=$query&usehistory=y"
curl $url_search -g -o esearch.xml
```
  
I use the same search parameters as before, the only difference being the `usehistory=y` bit in the url --- this indicates that I want to temporarily store the UIDs retrieved by ESearch on the Entrez History server, in order to pass them as an input to ESummary later on. When using this option, all IDs in the result are automatilcally stored on the server, i.e. there is no need to modify `retmax` parameter.

## ESummary

When a set of UIDs is stored on History server, its location is identified by an integer label called a Query key and an encoded cookie string called a Web environment, which are then used when refering to this set of UIDs in subsequent URL requests. Here I extract query key and web enviroment for the set of IDs generated by ESearch request from the resulting xml file `esearch.xml`, and then use them in the ESummary URL request, to find information on papers with these input IDs.


```bash
web=$(sed '3q;d' esearch.xml | sed -E 's/.*<WebEnv>([^<]+)<\/WebEnv>.*/\1/')
key=$(sed '3q;d' esearch.xml | sed -E 's/.*<QueryKey>([^<]+)<\/QueryKey>.*/\1/')
url_summary=$base"esummary.fcgi?db=pubmed&query_key=$key&WebEnv=$web"
curl $url_summary -g -o esummary.xml
```

## ELink

I also want to look at the citations for all those papers on gut metagenomes published in the last ten years. To do this, I could again use the input PMIDs stored on History server, this time with Elink API. 


```bash
url_link=$base"elink.fcgi?dbfrom=$db&linkname=pubmed_pubmed_citedin&query_key=$key&WebEnv=$web"
curl $url_link -g -o elink.xml
```

This is how you would do a request in batch mode and get citations for all the papers, i.e. list of papers citing __any__ of those input papers. However, the information for __individual__ papers is lost here. In order to get citations for each individual paper in separate xml file, IDs in the URL request should be specified in curly brackets, separated by commas. To do that, I use the text file with PMIDs generated in the previous example (I first parse the file in order to replace newline characters with commas and remove carriage returns).


```bash
ids=$(sed ':a;N;$!ba;s/\n/,/g' PMIDs.txt | tr -d '\r')
url_link_indiv=$base"elink.fcgi?dbfrom=$db&linkname=pubmed_pubmed_citedin&id={$ids}" 
curl $url_link_indiv -o elink.#1.xml
```

However, I don't want to work with 263 xml files --- remember, that's how many papers I had previously found --- I would actually prefer to have a single xml file with nodes for each input ID. Such output is generated when the IDs are specified as separate parameters in URL request, joined by `&`, e.g. `id=30078113&id=29934497` (the so-called 'by Id' mode).


```bash
ids=$(sed ':a;N;$!ba;s/\n/\&id=/g' PMIDs.txt | tr -d '\r')
url_link_byid=$base"elink.fcgi?dbfrom=$db&linkname=pubmed_pubmed_citedin&id=$ids" 
curl $url_link_byid -o elink.byid.xml
```

Now this is something I can load in R and work with.  

## xml2


```r
require(xml2)
esearch <- read_xml("esearch_pmid.xml")
esummary <- read_xml("esummary.xml")
elink <- read_xml("elink.byid.xml")
```

I've already extracted input PMIDs in the previous example.  


```r
ids <- xml_text(xml_find_all(esearch, "//Id"))
```

Now I also want to get the downloaded information for those papers.


```r
# for each paper
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
```



Note the dot in the `".//Id"` Xpath above - this specifies that I only want to retrieve Item nodes beneath the current node, i.e. for the current paper.  
Now, if you inspect `paper_info`, you'll see that different elements (i.e. papers) have some different categories. This is the information available for all the papers. 


```r
infos <- Reduce(intersect, lapply(paper_info,names)); infos
```

```
##  [1] "PubDate"         "EPubDate"        "Source"         
##  [4] "AuthorList"      "Author"          "LastAuthor"     
##  [7] "Title"           "Volume"          "Issue"          
## [10] "Pages"           "LangList"        "Lang"           
## [13] "NlmUniqueID"     "ISSN"            "ESSN"           
## [16] "PubTypeList"     "PubType"         "RecordStatus"   
## [19] "PubStatus"       "ArticleIds"      "pubmed"         
## [22] "rid"             "eid"             "History"        
## [25] "medline"         "entrez"          "References"     
## [28] "HasAbstract"     "PmcRefCount"     "FullJournalName"
## [31] "ELocationID"     "SO"
```

It's now easy to get a table summary for all the papers. I use `data.table` to gather data from list to tabulated format.  

```r
require(data.table)
list_summary <- lapply(paper_info, function(x){
  data.table(init=NA)[,I(infos):=as.list(x[infos])][,init:=NULL]
})
table_summary <- rbindlist(list_summary,idcol="PMID")
```

I'll make a few graphical summaries using some of this data. The code for generating these plots is given in the script at the end of the post.

![]({{ site.baseurl }}/assets/img/2018-12-03-retrieval-and-exploration-of-PubMed-citations_files/figure-html/unnamed-chunk-17-1.png)

There were no research papers about human gut metagenome published before 2014. Papers with the highest average number of citations were published in 2015, while the following two years, 2016 and 2017, saw generally the highest number of papers published. The number of publications decreased in 2018. Note that reviews are not included in this analysis.  

![]({{ site.baseurl }}/assets/img/2018-12-03-retrieval-and-exploration-of-PubMed-citations_files/figure-html/unnamed-chunk-18-1.png)

Most of these papers were published in PLoS One, Scientific Reports and Microbiome. Not surprisingly, the papers most cited by other PMC articles are published in Nature, Nature Communications, Nature Medicine and in Science.

Let's look at the list of PubMed articles citing any of the given papers.  
Note that this is the same as what I've done in the previous example, using `xml_find_all()` to find all nodes with paper IDs, and `xml_text()` to coerce these to character strings. The only difference is that here I first look for nodes matching "Link", in order not to retrieve the subject paper Id alongside the Ids of papers citing it.  


```r
all_citations <- xml_text(xml_find_all(xml_find_all(elink, "//Link"), ".//Id"))
head(all_citations)
```

```
## [1] "30233499" "29762673" "30450127" "30113497" "30112118" "30104497"
```

```r
length(unique(all_citations))
```

```
## [1] 2284
```

Again, note the dot in `".//Id"` Xpath above, specifying that I only want to find the nodes (here, Ids) which are beneath the current node (here, Links to citing PMIDs). If I used `"//Id"` instead, I would get the input papers' PMIDs as well.  
So, in total, there are 2284 PubMed articles citing any of the input articles.  

Which is the most cited article?  
<br>
To find this out, I parse IDs of papers citing each input paper.  


```r
paper_citations <- lapply(xml_find_all(elink, "//LinkSet"), function(x) {
  xml_text(xml_find_all(xml_find_all(x, ".//Link"), xpath=".//Id"))
})
names(paper_citations) <- ids
```



Now, among the input PMIDs, I can find the paper with the largest number of citations.  


```r
top_cited_paper <- papersDT[which.max(PmcRefCount)]
paper_info[top_cited_paper$PMID][[1]][c("PubDate","Source","LastAuthor","Title")]
```

```
## PubDate 
## "2015 Dec 10" 
## Source 
## "Nature" 
## LastAuthor 
## "Pedersen O" 
## Title 
## "Disentangling type 2 diabetes and metformin treatment signatures in the human gut microbiota."
```

And also all the papers that cite it.  

```r
paper_citations[top_cited_paper$PMID]
```

```
## $`26633628`
##   [1] "30445918" "30413727" "30409977" "30384259" "30373718" "30308002"
##   [7] "30266099" "30263058" "30261008" "30252913" "30249275" "30234027"
##  [13] "30189589" "30186236" "30108523" "30101405" "30078138" "30056386"
##  [19] "30052654" "30041479" "29997575" "29991496" "29988585" "29988362"
##  [25] "29985401" "29969576" "29960584" "29942096" "29934437" "29931613"
##  [31] "29915588" "29854817" "29853943" "29789365" "29764499" "29761590"
##  [37] "29712976" "29705929" "29703851" "29687645" "29682571" "29673211"
##  [43] "29669699" "29611319" "29596446" "29584630" "29562936" "29555994"
##  [49] "29474353" "29410651" "29407287" "29386298" "29371572" "29275161"
##  [55] "29255284" "29238752" "29204141" "29177508" "29176714" "29157127"
##  [61] "29148173" "29147991" "29107345" "29085571" "29066174" "29056925"
##  [67] "29018410" "29018189" "28973971" "28950720" "28937612" "28929327"
##  [73] "28906350" "28894183" "28884091" "28877164" "28874953" "28866243"
##  [79] "28843021" "28831566" "28815394" "28793934" "28776086" "28766937"
##  [85] "28765642" "28750650" "28739139" "28702329" "28643622" "28637315"
##  [91] "28615382" "28585938" "28585563" "28542929" "28531113" "28496408"
##  [97] "28476139" "28474371" "28467925" "28464031" "28449715" "28434033"
## [103] "28390093" "28275097" "28272137" "28258145" "28252538" "28217099"
## [109] "28208582" "28195358" "28184370" "28176229" "28143587" "28140326"
## [115] "28130771" "28119734" "28118083" "28062199" "28045919" "28045403"
## [121] "28035340" "27988219" "27965286" "27872127" "27859023" "27841267"
## [127] "27812984" "27807544" "27760558" "27746051" "27742762" "27681875"
## [133] "27638202" "27631013" "27623245" "27617199" "27565341" "27541295"
## [139] "27493135" "27471065" "27432166" "27418144" "27400279" "27350881"
## [145] "27324355" "27306058" "27304953" "27274912" "27216492" "27178527"
## [151] "27171425" "27159972" "27158266" "27146150" "27137897" "27126040"
## [157] "27126037" "27098841" "27011180" "26802434" "26780750"
```



The whole analysis pipline is available as the bash script in the [GitHub Gist](https://gist.github.com/anamariaelek/bfc04de34bbfea5c61523d439fb68139). I haven't gone to the trouble of making it a proper script (to be run with arguments, and such) but you could easily modify the code yourself --- for example, change the `query` string at the begining of the script to explore PubMed publications on other topics. For many more examples of both simple queries and more complex analyses refer to the [NCBI Help Manual](https://www.ncbi.nlm.nih.gov/books/NBK25497/#chapter2.Introduction).

# References

Read more about Entrez Utilities in the [NCBI Help Manual](https://www.ncbi.nlm.nih.gov/books/NBK25497/#chapter2.Introduction).  
If you are a fan of point-and-clicking in your web browser, but still could use an arbitrary E-utility pipeline, look at the [EBot](https://www.ncbi.nlm.nih.gov/Class/PowerTools/eutils/ebot/ebot.cgi) which can generate Perl scripts for you.  
