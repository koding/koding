#!/usr/bin/env bash
INSTALLED="Installed"
LINECOUNT="Linecount"
COUNT="Count"

BOOLEAN="Boolean"
NUMBER="Number"

function output {
  echo "{'category':'$1', 'name':'$2', 'type':'$3', 'value':$4}"
}
