#!/bin/bash

if ! which mongo; then
  echo 'error: mongo is not found'
  echo 'https://docs.mongodb.com/manual/installation/'
  exit 255
fi

set -o xtrace

version=$(mongo --version | head --lines=1 | awk '{ print $NF; }')

while IFS=".", read major minor revision; do
  major=$(echo $major | sed --expression 's/^v//')
  if [[ $major -ge 3 ]]; then
    exit 0
  elif [[ $major -eq 2 && $minor -ge 4 ]]; then
    exit 0
  else
    echo 'error: mongo version must be 2.4.x or 3.x'
    exit 1
  fi
done < <(echo $version)
