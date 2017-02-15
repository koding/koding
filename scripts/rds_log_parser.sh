#!/bin/bash

#
# This scripts fetches all the logs from RDS and puts into current folder
#
# After fectching all the logs from RDS, you can analyze them with the following command
#
#   perl ./pgbadger/pgbadger -j 8  --incremental --outdir /home/ec2-user --prefix '%t:%r:%u@%d:[%p]:' postgresql.log.2015-*
#
# After analyzing them you can fetch the results to your computer with the following command
#
#   rsync -av --exclude '*.bin' ec2-user@ec2-52-0-144-82.compute-1.amazonaws.com:/home/ec2-user/2015/ ./pgreport
#

DB_NAME="prod0"

if [ ! -n "$AWS_ACCESS_KEY" ]; then
	echo "AWS_ACCESS_KEY should be set"
	exit 1
fi

if [ ! -n "$AWS_SECRET_KEY" ]; then
	echo "AWS_SECRET_KEY should be set"
	exit 1
fi

if [ ! -n "$AWS_RDS_HOME" ]; then
	echo "AWS_RDS_HOME should be set"
	exit 1
fi

files=$(rds-describe-db-log-files $DB_NAME --access-key-id $AWS_ACCESS_KEY --secret-key $AWS_SECRET_KEY | awk '{print $2}')

oldIFS="$IFS"
IFS='
'
IFS=${IFS:0:1}
lines=($files)
IFS="$oldIFS"

for line in "${lines[@]}"; do
	if [ -e ${line:6} ]; then echo ${line:6} "already exists"
	else
		echo ${line:6} "doesnt exist, downloading"
		rds-download-db-logfile $DB_NAME --log-file-name $line --access-key-id $ACCESS_KEY --secret-key $SECRET_KEY --connection-timeout 3000000 >${line:6} || echo ${line:6} "couldn't be downloaded"
		echo "done with" ${line:6}
	fi
done

exit 0
