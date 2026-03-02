FROM rocker/geospatial:4.0.2

ENV TZ=America/Los_Angeles

# copy working files over
COPY . /home/rstudio/brazil-mortality-release

# install dependencies described in DESCRIPTION file
# GITHUB_PAT is passed at build time (--build-arg) to avoid rate limits; not stored in image
ARG GITHUB_PAT
RUN GITHUB_PAT=${GITHUB_PAT} Rscript -e "devtools::install_deps('/home/rstudio/brazil-mortality-release')"

RUN touch /home/rstudio/brazil-mortality-release/.here

# Set up RStudio preferences with vim keybindings
RUN mkdir -p /home/rstudio/.config/rstudio
COPY rstudio-prefs.json /home/rstudio/.config/rstudio/rstudio-prefs.json

RUN chown -R rstudio /home/rstudio





