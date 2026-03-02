#!/bin/zsh

git credential fill <<< $'protocol=https\nhost=github.com\n'
echo "use 'export GITHUB_PAT=ghp_yourtoken'"
echo "where ghp_yourtoken is the password that was printed above"
echo "then you can run ./build_docker.sh"
