#!/usr/bin/env bash

MYDIR="$(dirname "$(which "$0")")"
source $MYDIR/output.sh
output "bashrc line count" $NUMBER `$MYDIR/number_of_lines.sh ~/.bashrc`
