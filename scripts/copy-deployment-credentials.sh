#!/bin/bash

function clone() {
	declare REPOSITORY=$1
	declare BRANCH=$2
	git clone --branch $BRANCH --depth 1 git@github.com:koding/$REPOSITORY.git
}

BRANCH=${BRANCH:-$(git rev-parse --abbrev-ref HEAD)}
BRANCH=${BRANCH:master}

clone vault $BRANCH || clone vault master
clone credential $BRANCH || clone credential master

cp -Rv credential/config/* vault/config/* config/
cp -Rv credential/scripts/* vault/scripts/* scripts/
