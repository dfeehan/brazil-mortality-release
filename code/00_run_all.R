con <- file("run_all.log")
sink(con, append=TRUE, split=TRUE)

# temporary URL for our survey data
survey_url <- "https://www.dropbox.com/s/sfrmpx7pgmg9445/data.zip?dl=1"

#root.dir <- "brazil-mortality-release"
root.dir <- "."
code.dir <- file.path(root.dir, 'code') 

###########
## create directories
out.dir <- file.path(root.dir, 'out')
data.dir <- file.path(root.dir, 'data')

dir.create(out.dir, showWarnings=FALSE)

###################
## download the survey data 
httr::GET(url = survey_url,
          httr::write_disk(file.path(root.dir, 'data.zip'),
                           overwrite = TRUE))

## unzip the survey data
unzip(file.path(root.dir, "data.zip"),
      exdir=file.path(root.dir))

###################
## Run all of the scripts
rmd_files <- list.files(path=code.dir, pattern=".Rmd")

## remove 99_vr_comparison.Rmd (which is a helper file)
rmd_files <- purrr::discard(rmd_files, .p=~stringr::str_detect(.x,'99_vr_comparison'))


for (cur_file in rmd_files) {
  cat("================================\n")
  tictoc::tic(glue::glue("Running {cur_file}"))
  cat("Running ", cur_file, "\n")
  rmarkdown::render(file.path(code.dir, cur_file))
  tictoc::toc()
  cat("================================\n")
}

sink()
