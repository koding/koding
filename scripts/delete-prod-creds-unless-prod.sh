#!/bin/bash

if [ "$CONFIG" != "prod" ]; then
  rm -rf credential/
  rm -rf config/main.prod.coffee config/credentials.production.coffee config/sumologic/prod.*
fi
