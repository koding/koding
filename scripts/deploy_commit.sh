#!/bin/bash

set -euo pipefail

export ORIGIN=${ORIGIN:-koding}
export TARGET=${TARGET:-production}
export COMMIT_ID=$1 # if $1 does not exist, bash will fail.

git fetch $ORIGIN
git checkout -b $TARGET || git checkout -f $TARGET
git reset --hard $ORIGIN/$TARGET
git cherry-pick $COMMIT_ID

echo "before tagging" && git tag -n -l $TARGET-deployment
git tag -f $TARGET-deployment
echo "after tagging" && git tag -n -l $TARGET-deployment

git push -f $ORIGIN $TARGET $TARGET-deployment
