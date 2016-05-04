#!/bin/bash

git clone git@github.com:koding/credential.git
git clone git@github.com:koding/vault.git
cp -R credential/config/* config/
cp -R credential/scripts/* scripts/
