#!/bin/zsh

docker run -d \
  --rm \
  -p 8111:8888 \
  --memory="60g" \
  -e PASSWORD=pass \
  --name brazil \
  -v $(pwd):/home/rstudio/ \
  brazil-replication


#  --memory-swap="12g" \
#  --cpus="12.0" \
