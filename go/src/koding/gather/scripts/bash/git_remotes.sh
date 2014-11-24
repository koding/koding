#!/usr/bin/env bash
./git_repos.sh | while read w; do git --git-dir=$w remote -v | grep fetch | awk '{print $2}'; done
