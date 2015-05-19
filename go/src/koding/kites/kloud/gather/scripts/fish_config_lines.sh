#!/usr/bin/env bash

source output.sh
output $LINECOUNT "fish config" $NUMBER `./number_of_lines.sh ~/.config/fish/config.fish`
