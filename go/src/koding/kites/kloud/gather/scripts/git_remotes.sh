#!/usr/bin/env bash
./git_repos.sh | while read w; do git -C $w remote -v | grep fetch | awk '{print pwd " " $2}' pwd="$PWD"; done
