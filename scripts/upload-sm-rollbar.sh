#!/bin/bash

# This script uploads sourcemaps to rollbar.com. Sourcemaps
# make it easier to debug client side errors that occur in
# production.

website=website/a/p/p
rollbar_token=6b1f2079d843423fbc0037b59bd13486
version=`cat VERSION`
folderpath=$website/$version

if [ ! -d $folderpath ]; then
  echo "$folderpath dir doesn't exists"
fi

cd $folderpath
for file in $(ls -l | grep ".js$" | awk '{print $9}')
do
  curl https://api.rollbar.com/api/1/sourcemap \
    -F access_token=$rollbar_token\
    -F version=$version \
    -F minified_url=http://sandbox.koding.com/a/p/p/$version/$file \
    -F source_map=@$file.map
done

rm -f *.map
