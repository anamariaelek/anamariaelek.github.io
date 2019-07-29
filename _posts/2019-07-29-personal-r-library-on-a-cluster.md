---
title: Personal R library on a cluster
author: Anamaria Elek 
date: 2019-07-29
output: 
  html_document:
  keep_md: true
tags: [R]
feature-img: "assets/img/2019-07-29-personal-r-library-on-a-cluster/library.jpg"
---

Using R is often a pain. Using R on HPC is often even more so. The issue I've struggled with for a while now was how to (relatively simply) maintain a (relatively useable) library, i.e. how to install and keep track of specific versions of packages without running into permission issues, and without having to occasionally re-install everything from the scratch because of the dependencies conflicts.

I eventually came up with a relatively straightforward solution. In short: create a personal library and use it as a default location to install packages -- this is accomplished by adding to your `.Rprofile` file the handy `.libPaths()` tweak described in [this post](https://milesmcbain.xyz/hacking-r-library-paths/).

A more detailed explanation.  

Create a library directory in your home folder, e.g. `~/R/3.6` for R version 3.6. Then add the following lines to your `~/.Rprofile`, making sure that the path in the last line matches the library directory created previously.
```
# user specific library
set_lib_paths <- function(lib_vec) {

  lib_vec <- normalizePath(lib_vec, mustWork = TRUE)

  shim_fun <- .libPaths
  shim_env <- new.env(parent = environment(shim_fun))
  shim_env$.Library <- character()
  shim_env$.Library.site <- character()

  environment(shim_fun) <- shim_env
  shim_fun(lib_vec)

}
set_lib_paths("~/R/3.6")
```

To check that everything is working, restart your bash shell, start R and see if the `.libPaths()` outputs the specified library location.

# References

Miles McBain's [blog post](https://milesmcbain.xyz/hacking-r-library-paths/) on hacking R library paths. 