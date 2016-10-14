#!/bin/bash

if [[ -f $GOPATH/bin/github-release ]];
then
    go get -f -u github.com/aktau/github-release
fi

if [[ "$GITHUB_TOKEN" == "" ]];
then
    echo "You need to set GITHUB_TOKEN as an env var"
    exit 1
fi

version=$(cat version)

# Create the release
github-release release -u banno -r terraform-provider-marathon -t "$version"

# Upload the binaries
github-release upload -u banno -r terraform-provider-marathon -f bin/terraform-provider-marathon-linux -t "$version" --name terraform-provider-marathon-linux
github-release upload -u banno -r terraform-provider-marathon -f bin/terraform-provider-marathon-osx -t "$version" --name terraform-provider-marathon-osx
