#!/bin/bash

# This script uploads sourcemaps to rollbar.com. Sourcemaps
# make it easier to debug client side errors that occur in
# production.

website=website/a/p/p
rollbar_token=9726e570e4694e09b3702df3a7a1acbc
version=`cat VERSION`

if [ ! -d $website ]; then
  echo "$website dir doesn't exists"
fi

cd $website
for file in $(ls -l | grep ".js$" | awk '{print $9}')
do
  curl https://api.rollbar.com/api/1/sourcemap \
    -F access_token=$rollbar_token\
    -F version=1 \
    -F minified_url=https://koding.com/a/p/p/$file \
    -F source_map=@$file.map
done
