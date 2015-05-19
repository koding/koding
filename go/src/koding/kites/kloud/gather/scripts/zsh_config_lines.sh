#!/usr/bin/env bash

source output.sh
output $LINECOUNT "Zsh config" $NUMBER `./number_of_lines.sh ~/.zshrc`
