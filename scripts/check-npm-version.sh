#!/bin/bash

VERSION=$(npm --version)

while IFS=".", read MAJOR MINOR REVISION; do
  if [[ $MAJOR -lt 3 ]]; then
    MISMATCH=1
  fi
done < <(echo $VERSION)

if [[ -n "$MISMATCH" ]]; then
  echo "error: npm version must be 3.x or greater"
  exit 1
fi
