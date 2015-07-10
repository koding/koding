#!/bin/bash

git clone git@github.com:koding/credential.git
cp credential/config/main.prod.coffee config/
cp -R credential/scripts/* scripts/
