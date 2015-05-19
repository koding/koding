#!/usr/bin/env bash

source output.sh
output $LINECOUNT "Bash config" $NUMBER `./number_of_lines.sh ~/.bashrc`
