#!/usr/bin/env bash
if which $1 > /dev/null; then
  echo 1
else
  echo 0
fi
