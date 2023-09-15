---
title: "README"
output: html_document
---

NOTE: Matt likes the [groundhog package](https://groundhogr.com/using/)
which looks like it might be a lighter alternative to Docker

# TODO

* LEFT OFF: need packages lemon and tune
* need a way to get data into image; created data.zip, trying to work with that
- be sure capital-design.csv only has columns we need
- figure out exactly what should start in the data/ zip file
  -> not sure we need data/vr_prepped; I think these get created by 01_vr_completeness?
  

# Brazil sibling/network mortality analysis

This directory contains the files that produce estimates from the sibling
and network methods, and then compares those estimates to the vital registration data.

It is organized into subdirectories:

* `code` - has R scripts  
  * `00_sample_map.Rmd` - create the map showing the cities in our sample
  * `01_vr_completeness.Rmd` - TODO
  * `02_get_vr_estimates.Rmd` - calculate VR death rates for each city and region 
  * `03_network_estimates.Rmd` - TODO
  * `04_sibling_estimates.Rmd` - TODO
  * `05_vr_comparison.Rmd` - TODO
* `data` - has the data used in the analysis
  * `vr_raw` - raw vital registration data
  * `vr_prepped` - VR data after being prepared for comparison
  

## DOCKER

It is likely that you have different versions of R and specific R packages than we did
when we wrote our code.  Thus, we recommend using Docker to replicate our results.
Using Docker will ensure that you have exactly the same computing environment that we did
when we conducted our analyses.

To use Docker

1. [Install Docker Desktop](https://www.docker.com/get-started) (if you don't already have it)
1. Clone this repository
1. Be sure that your current working directory is the one that you downloaded the repository into. It's probably called `brazil-mortality-release/`
1. Build the docker image.
   `docker build --rm -t brazil-replication .`
   This step will likely take a little time, as Docker builds your image (including installing various R packages)
1. Run the docker image
   `docker run -d --rm -p 8888:8787 -e PASSWORD=pass --name brazil brazil-replication`
   OR [TODO FIGURE OUT WHICH IS BETTER]
   `docker run -d --rm -p 8888:8787 -e PASSWORD=pass --name brazil -v $(pwd):/home/rstudio/  brazil-replication`
1. Open a web browser and point it to localhost:8888
1. Log onto Rstudio with username 'rstudio' and password 'pass'
1. Open the file `brazil-mortality-release/code/00-run-all.r`
1. Running the file should replicate everything. 
