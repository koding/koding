#!/bin/bash -ex

VERSION_FILE_URL=$S3_BUCKET/$WERCKER_GIT_BRANCH.version

if [ -z $(s3cmd ls $VERSION_FILE_URL) ]
then
    echo 0 > VERSION
    s3cmd put VERSION $VERSION_FILE_URL
else
    s3cmd get $VERSION_FILE_URL VERSION
fi

VERSION=$((`cat VERSION` + 1))
echo $VERSION > VERSION
s3cmd put VERSION $S3_BUCKET/$WERCKER_GIT_BRANCH.version
