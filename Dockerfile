FROM rocker/geospatial:4.0.2

# copy working files over
COPY . /home/rstudio/brazil-mortality-release

# install dependencies described in DESCRIPTION file
RUN Rscript -e "devtools::install_deps('/home/rstudio/brazil-mortality-release')"

RUN touch /home/rstudio/brazil-mortality-release/.here

RUN chown -R rstudio /home/rstudio





