#!/bin/bash

NAME=$1
SHA=$2
MESSAGE=$3
STATUS=$4
PERCENTAGE=$5

curl -X POST -d "name=$NAME&sha=$SHA&message=$MESSAGE&status=$STATUS&percentage=$PERCENTAGE" http://cihangir.ngrok.com/hook/wercker/incoming
