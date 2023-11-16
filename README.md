---
title: "Brazil mortality replication code"
output: html_document
---

# TODO - FINAL CHECKLIST

* be sure that the data in the zipfile are what we want, and find a way (other than dropbox) to distribute 

# Brazil sibling/network mortality analysis

This directory contains the files that produce estimates from the sibling
and network methods, and then compares those estimates to the vital registration data.

It is organized into subdirectories:

* `code` - has R scripts  
  * `00_run_all.R` - a script that downloads the data and runs everything
  * `00_sample_map.Rmd` - create the map showing the cities in our sample
  * `01_vr_completeness.Rmd` - summarize estimated VR completeness by city
  * `02_get_vr_estimates.Rmd` - calculate VR death rates for each city and region 
  * `03_network_estimates.Rmd` - calculate network estimates 
  * `04_sibling_estimates.Rmd` - calculate sibling estimates
  * `05_run_comparison.Rmd` - run comparisons between estimates and the vital registration
  * `06_plots.Rmd` - make several plots
  * `99_vr_comparison.Rmd` - has the code that compares estimates to VR; only to be run by `00_run_all.R`
* `data` - has the data used in the analysis; this will be downloaded by `00_run_all.R`
  * `cities.csv` - data on the cities in our study
  * `ibge-capture-recapture` - results from IBGE's capture-recapture study
  * `survey` - data from the survey
    - `bootstrap_weights_1k.csv` - bootstrap resampling weights that account for our survey's complex sample design
    - `individual.csv` - data on the respondents to the survey
    - `network_reports.csv` - data on deaths reported in the network part of the survey (one row per reported death)
    - `sibling_reports.csv` - data on siblings reported in the sibling module (one row per reported sib)
  * `vr` - raw vital registration data
    - `deaths` - data on deaths
    - `popn` - data on popn size
  * `vr_prepped` - VR data after being prepared for comparison (created by script)
  

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
   OR, to mount a local drive, you will need something like:
   `docker run -d --rm -p 8888:8787 -e PASSWORD=pass --name brazil -v $(pwd):/home/rstudio/  brazil-replication`
1. Open a web browser and point it to localhost:8888
1. Log onto Rstudio with username 'rstudio' and password 'pass'
1. Open the file `brazil-mortality-release/code/00_run_all.r`
1. Running the file should download the data and replicate everything. 
