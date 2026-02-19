FROM rocker/geospatial:4.0.2

ENV TZ=America/Los_Angeles

# copy working files over
COPY . /home/rstudio/brazil-mortality-release

# install dependencies described in DESCRIPTION file
RUN Rscript -e "devtools::install_deps('/home/rstudio/brazil-mortality-release')"

RUN touch /home/rstudio/brazil-mortality-release/.here

# Set up RStudio preferences with vim keybindings
RUN mkdir -p /home/rstudio/.config/rstudio
COPY rstudio-prefs.json /home/rstudio/.config/rstudio/rstudio-prefs.json

RUN chown -R rstudio /home/rstudio





