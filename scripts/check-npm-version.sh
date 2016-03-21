#!/bin/bash

VERSION=$(npm --version)

while IFS=".", read MAJOR MINOR REVISION; do
  if [[ $MAJOR -lt 2 ]]; then
    MISMATCH=1
  elif [[ $MAJOR -eq 2 && $MINOR -lt 9 ]]; then
    MISMATCH=1
  fi
done < <(echo $VERSION)

if [[ -n "$MISMATCH" ]]; then
  echo "error: npm version must be 2.9.x or greater"
  exit 1
fi
