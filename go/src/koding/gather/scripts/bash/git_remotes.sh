#!/usr/bin/env bash
./scripts/bash/git_repos.sh | while read w; do git --git-dir=$w remote -v | grep fetch | awk '{print pwd " " $2}' pwd="$PWD"; done
