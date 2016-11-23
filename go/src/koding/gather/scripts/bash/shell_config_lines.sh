#!/usr/bin/env bash
file=$1
if [ -e "$file" ]
then
  wc -l $file | awk '{print $1}'
else
  echo 0
fi
