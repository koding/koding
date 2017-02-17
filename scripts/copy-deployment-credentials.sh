#!/bin/bash

function clone() {
	declare repository=$1
	declare branch=$2
	declare repository_url="git@github.com:koding/$repository.git"

	if [[ -n "$GITHUB_ACCESS_TOKEN" ]]; then
		repository_url="https://$GITHUB_ACCESS_TOKEN:x-oauth-basic@github.com/koding/$repository.git"
	fi

	git clone --branch $branch --depth 1 $repository_url
}

BRANCH=${BRANCH:-$(git rev-parse --abbrev-ref HEAD)}
BRANCH=${BRANCH:master}

clone vault $BRANCH || clone vault master
clone credential $BRANCH || clone credential master

cp -Rv credential/config/* vault/config/* config/
cp -Rv credential/scripts/* vault/scripts/* scripts/
