#!/bin/bash

git clone git@github.com:koding/credential.git
git clone git@github.com:koding/vault.git
cp -Rv credential/config/* config/
cp -Rv credential/scripts/* scripts/
