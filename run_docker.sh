#!/bin/zsh

export DOCKER_DEFAULT_PLATFORM=linux/amd64

docker run -d \
  --rm \
  -p 8111:8787 \
  --memory="80g" \
  -e PASSWORD=pass \
  --name brazil \
  -v $(pwd):/home/rstudio/ \
  brazil-replication


#  --memory-swap="12g" \
#  --cpus="12.0" \
