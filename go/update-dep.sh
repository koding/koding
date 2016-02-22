#! /bin/bash

go list ./... | grep github.com | sed -e 's!_/home/tpiha/koding/go/src/!!' |  \
while read line ;
do
    rm -rf src/$line
    go get $line
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        rm -rf src/$line/.git

        ./build.sh

        RESULT=$?
        if [ $RESULT -eq 0 ]; then
            git add --ignore-removal .
            git commit -a -m "updated $line"
        else
            git checkout .
            git clean -f
        fi
    else
        git checkout .
        git clean -f
    fi
done
