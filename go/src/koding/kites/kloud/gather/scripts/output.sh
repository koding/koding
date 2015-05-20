#!/usr/bin/env bash

BOOLEAN="boolean"
NUMBER="number"

function output {
  echo "{\"name\":\"$1\", \"type\":\"$2\", \"$2\":$3}"
}
