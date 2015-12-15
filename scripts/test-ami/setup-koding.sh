#!/bin/bash

# Set up working environment

REPOSITORY_PATH=/opt/koding

## Clone repository

git clone --recursive git@github.com:koding/koding.git $REPOSITORY_PATH

## Configure working environment

cd $REPOSITORY_PATH
npm install --unsafe-perm

./configure
sudo ./run buildservices force || :


# Cleanup

git clean -fdX

exit 0


# File variables

## Local variables:
## outline-regexp: "#+ "
## End:
