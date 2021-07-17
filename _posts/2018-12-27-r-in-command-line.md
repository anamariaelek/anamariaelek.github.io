---
title: R in the command line
author: Anamaria Elek 
date: 2018-12-27
output: 
  html_document:
  keep_md: true
tags: [R, Bash, docopt, Rscript]
feature-img: "assets/img/2018-12-27-r-in-command-line/cml.jpg"
---

There is more than one way to make your R scripts play nicely with the command line. This post gives an overview of several different approaches.  

A good deal of any kind of data analysis can be done with a neat piece of code in an R script. Even more can be done (or it can be done in a neater way) with several organized scripts and appropriate `source()`ing. But there are limits and drawbacks to this approach, the first one being poor reproducibility. Very soon it becomes teadious to re-run pieces of code as they are needed. And it becomes cumbersome to change specific values in the code to re-run the analysis with different parameters. On top of that, the analysis almost always includes more than just R code, and then it really becomes challenging not to get it all mixed up.
One apparent solution in the described scenario would be to make a pipeline using a workflow managment system (e.g. Snakemake) which allows you to specify inputs and outputs in the workflow description, and to reference them from within your R script. This is often sufficient, and I will not go into it right now. However, if you need even more fkexibility --- e.g. you want to be able to feed your script some optional arguments and parameters --- you can modify your script so that it effectively mimicks a proper command line program. Below I describe several ways in which R scripts can be run directly from command line.

# `Rscript`
Probably the most common way to run R scripts from the command line is using `Rscript`, which ships with R, so you don't really need to install anything in order to use it.  

In order to pass the arguments to script from comand line, you should include `comandArgs(TRUE)` in your script. You can then access the arguments like so:  

```bash
#!/usr/bin/env Rscript
args <- commandArgs(TRUE)
string <- collapse(args, sep=" + "))
```  

Note the use of the hashbang (shebang) at the very begining of the script, which ensures that the script will be executed by the appropriate interpreter.  

# `r`

`r` is a program written in C for simple execution of R scripts and one-liners. It is aptly named little r because, as per the [official documentation](http://dirk.eddelbuettel.com/code/littler/README), it provides the language interpreter without the R environment. It does this by overriding some of the user-defined environment variables by the values which are hard-coded in the `r` implementation itself. Eliminating the dependencies in this way makes start and execution faster.  

`r` can be used for sourcing single files from the command line. When running scripts using `r`, make sure to include the appropriate shebang at the begining:  

```bash
#!/usr/bin/env r
# R code here
```

Apart from simply running R scripts, `r` allows you to combine R and the common Unix piping (`|`). You can redirect output of other commands to R like so:  

```bash
echo 'paste0(1:7,c("st","nd","rd",rep("th",4)))' | r
```
```
"1st" "2nd" "3rd" "4th" "5th" "6th" "7th"
```

`r` also allows for inline evaluation of R expressions directly in the command line using the `-e` flag. It can come in handy to combine this with `-d` flag which assigns stdin to a data.frame named X. For example, to list files in the current directory using bash, and order them by size using R, you could do:  

```
ls -l | r -de 'X[order(X[,1])]'
```
```
total 7
drwxrwxr-x 5 aelek aelek 4096 Dec 27 16:08 data
-rw-rw-r-- 1 aelek aelek  361 Dec 27 16:08 README.md
-rw-rw-r-- 1 aelek aelek  495 Dec 27 16:08 script.R
```

Finally, `r` is quicker to start than either `R` itself, or the alternative scripting tool `Rscript`.  

`r` vignette contains several handy scripts covering some of the tasks you might do on a daily basis, like installing R packages and kniting files, and which you might want to do directly from the command line --- definitely worth checking out.  

# `R CMD BATCH`

The main advantages of running R CMD BATCH are that it allows executing multiple R files using a single command, and it captures warnings and errors, and outputs time required for each script to run (obtained by calling `proc.time()` at the end of the session).  

```bash
R CMD BATCH script.R script.Rout
```

Now `script.Rout` file contains all the captured output (alongside the R code that generated it --- to get just the output in the `.Rout` file, use `--slave` flag). The obvious downside here is that there is no straightforward way to specify input or output files, or arguments, directly on the command line.


# `docopt`

Probably the most flexible one, `docopt` R package is an R implementation of docopt, a command-line interface description language. This is basically a formalized help message in which the options, arguments and usage patterns for a script are defined. `docopt` extracts all this information and generates a command-line arguments parser. This way, R scipts can be run just as any conventional command line program. 

The important bits are to include hashbang at the begining of the script, and to write a properly structured help message, wich is to be parsed by `docopt()`. The help message should contain `Usage` and `Options` parts in which the appropriate usage pattern and flags are defined, respectively. Other than those, it can include any amount of text which explains what the script should do and how it should be used. One section I also find useful to include is `Arguments`, explaining there the arguments which should be passed to the R script.  

Here's an example of a command-line interface definition for the R script that extracts sequence variants from the `vcf` file to `rds` object:  

```r
#!/usr/bin/Rscript
'CONVERT VCF TO RDS

This script reads into R an input vcf file containing short sequence variants
called by Freebayes and annotated with SnpSift/SnpEff, extracts relevant 
information to a tidy data.frame and saves it as an rds object.

Usage:
   script.R <input> [-o <output> -h]

Arguments:
   <input>              Input vcf file with called and annotated variants.

Options:
  -o                    Output file name. By default, same as input, except the extension.
  -h --help             Show this screen.

' -> doc
opts <- docopt(doc)
vcf_file <- opts$input
rds_file <- opts$o

# R code here
```

Now this script can be called from command line:

```bash
script.R input.vcf -o snv.rds
```

# Resources
* [Rscript](http://finzi.psych.upenn.edu/R/library/utils/html/Rscript.html)
* [r](http://dirk.eddelbuettel.com/code/littler.html)
* [R CMD BATCH](https://stat.ethz.ch/R-manual/R-devel/library/utils/html/BATCH.html)
* [docopt](https://github.com/docopt/docopt.R) and [docopt implementation in R](http://docopt.org/)  
