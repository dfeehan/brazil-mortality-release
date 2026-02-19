#!/bin/zsh

# uncomment if running on apple silicon
#export DOCKER_DEFAULT_PLATFORM=linux/amd64

docker build --rm -t brazil-replication . 
