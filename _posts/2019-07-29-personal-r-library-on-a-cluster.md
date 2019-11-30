---
title: Personal R library
author: Anamaria Elek 
date: 2019-07-29
output: 
  html_document:
  keep_md: true
tags: [R]
feature-img: "assets/img/2019-07-29-personal-r-library-on-a-cluster/library.jpg"
---

Whats and hows about the location of your R library.

There are several R related enviroment variables:  

* `R_HOME` = directory where R is installed  
* `R_LIBS` = unset by default; if specified, it should be a colon-separated list of directories at which R library trees are rooted  
* `R_LIBS_USER` = set to directory `R/R.version$platform-library/x.y` of the home directory  

The library search path is initialized at startup from the environment variable `R_LIBS`, followed by those in `R_LIBS_USER`. 

Inside R, the following variables can be defined:

* `.Library` = a character string giving the location of the default library, i.e. the `library` subdirectory of `R_HOME`  
* .`Library.site` = a (possibly empty) character vector giving the locations of the site libraries, by default the `site-library` subdirectory of `R_HOME` (which may not exist)  

Ue R function `.libPaths()` for getting or setting the library trees that R knows about (and hence uses when looking for packages). If given no argument, the function returns a character vector with the currently active library trees. If it is called with argument `new`, the library search path is set to the existing directories in `unique(c(new, .Library.site, .Library))`.

In order to define a cutom location for an r library, add the following to your `.Rprofile`:

```
.libPaths("/path/to/R_3.5_libs")
```

and make sure to install new packages in this library by specifying the argument `lib="/software/asebe/R_3.5_libs"`
