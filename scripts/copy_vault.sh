#! /bin/bash

set -o errexit

#  make relative paths work.
cd $(dirname $0)/..

log() {
	echo "$(date) [info] $1"
}

if [ ! -d "./vault" ]; then
	log "vault folder does not exist at ./vault"
	log "trying to clone it"
	git clone git@github.com:koding/vault.git ./vault
fi

cd ./vault
log "getting status"

# echo "asdfa" $?
if [ ! -d './.git' ]; then
	log "vault folder is not a git folder, skip updating"
	log "there can be misconfigurations in your system, just sayin.."
fi

# get the latest upstream changes
git fetch

v=$(git diff-tree -r --name-only --no-commit-id HEAD..origin/master 2>&1)
if [ -z "$v" ]; then
	echo "vault is up-to-date with origin/master!"
fi

git pull --rebase --autostash origin master
