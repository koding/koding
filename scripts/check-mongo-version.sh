#!/bin/bash

if ! which mongo >/dev/null 2>&1; then
	echo 'error: mongo is not found'
	echo 'https://docs.mongodb.com/manual/installation/#mongodb-community-edition'
	exit 255
fi

version=$(mongo --version | head -n1 | awk '{ print $NF; }')

while IFS=".", read major minor revision; do
	major=$(echo $major | sed -e 's/^v//')
	if [[ $major -ge 3 ]]; then
		exit 0
	else
		echo 'error: mongo version must be 3.x'
		echo ''
		echo 'for mac you might use to upgrade: '
		echo '  curl -O http://downloads.mongodb.org/osx/mongodb-osx-x86_64-3.2.8.tgz'
		echo '  tar -zxvf mongodb-osx-x86_64-3.2.8.tgz'
		echo '  cp -R ./mongodb-osx-x86_64-3.2.8/bin/* /usr/local/bin'
		echo '  rm -rf ./mongodb-osx-x86_64-3.2.8'
		exit 1
	fi
done < <(echo $version)
