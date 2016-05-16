#!/bin/bash

git clone --depth 1 git@github.com:koding/credential.git
git clone --depth 1 git@github.com:koding/vault.git

cp -Rv credential/config/* config/
cp -Rv credential/scripts/* scripts/
