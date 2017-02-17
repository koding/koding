#!/bin/bash

function clone() {
	declare repository=$1
	declare branch=$2
	git clone --branch $branch --depth 1 git@github.com:koding/$repository.git
}

BRANCH=${BRANCH:-$(git rev-parse --abbrev-ref HEAD)}
BRANCH=${BRANCH:master}

clone vault $BRANCH || clone vault master
clone credential $BRANCH || clone credential master

cp -Rv credential/config/* vault/config/* config/
cp -Rv credential/scripts/* vault/scripts/* scripts/
