#!/bin/bash

# This script uploads sourcemaps to rollbar.com. Sourcemaps
# make it easier to debug client side errors that occur in
# production.

WEBSITE=$(dirname $0)/../website/a/p/p
ROLLBAR_TOKEN=6b1f2079d843423fbc0037b59bd13486
VERSION=`cat VERSION`
FOLDERPATH=$WEBSITE/$VERSION

if [ ! -d $FOLDERPATH ]; then
  echo "ERROR: '$FOLDERPATH' dir doesn't exists...sourcemaps won't be uploaded to Rollbar"
  exit 1
fi

cd $FOLDERPATH
for file in $(ls -l | grep ".js$" | awk '{print $9}')
do
  curl https://api.rollbar.com/api/1/sourcemap \
    -F access_token=$ROLLBAR_TOKEN\
    -F version=$VERSION \
    -F minified_url=https://koding.com/a/p/p/$VERSION/$file \
    -F source_map=@$file.map
done

rm -f *.map
