#!/bin/bash

# this script checks the environment name acts according to it, will be only
# used in EB envs
#
# if latest, uses the latest-deployment tag's sha
# if production, uses the latest-deployment tag's sha
# else: just use the standart git rev

prods=(
	koding-proxy-ap-s-e-1
	koding-proxy-eu-west-1
	koding-proxy-us-east-1
	koding-proxy-us-west-2
	koding-prod
)
for i in "${prods[@]}"; do
	if [ "$EB_ENV_NAME" == "$i" ]; then
		git checkout production-deployment
	fi
done

if [ "$EB_ENV_NAME" == "koding-latest" ]; then
	git checkout latest-deployment
fi

#
# "koding-proxy-ap-s-e-1"
# "koding-proxy-eu-west-1"
# "koding-proxy-us-east-1"
# "koding-proxy-us-west-2"
# "koding-prod"
#
# "koding-latest"
# "koding-sandbox"
#
# "koding-proxy-dev-us-e-1"
#

version=$(git rev-parse --short HEAD)

# output version file
echo $version >$WERCKER_ROOT/VERSION

# output archive name, that will be used for version archive name
echo $(date "+%Y-%m-%dT%H:%M:%S")_$version.zip >$WERCKER_ROOT/ARCHIVE_NAME
