#!/bin/bash

while getopts "i:" opt; do
	case "$opt" in
		i)
			index=$OPTARG
			;;
	esac
done

size=${#index}

if [[ size -eq 0 ]]; then
	echo "Error: must specify Algolia index to clear"
	exit 1
fi

echo "clearing index: $index..."

curl -X POST \
	-H "X-Algolia-API-Key: $KONFIG_SOCIALAPI_ALGOLIA_APISECRETKEY" \
	-H "X-Algolia-Application-Id: $KONFIG_SOCIALAPI_ALGOLIA_APPID" \
	"https://$KONFIG_SOCIALAPI_ALGOLIA_APPID.algolia.io/1/indexes/$index/clear"
