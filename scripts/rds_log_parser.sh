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

# worker_rds_log_parser
#   Access Key ID:
#       AKIAJX6IPI3PQCS3GJ6Q
#   Secret Access Key:
#       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
# it has only access to AmazonRDSReadOnlyAccess
DB_NAME="prod0"
ACCESS_KEY="AKIAJX6IPI3PQCS3GJ6Q"
SECRET_KEY="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"


if [ ! -n "$AWS_RDS_HOME" ]; then
    echo "AWS_RDS_HOME should be set"
    exit 1
fi

files=$(rds-describe-db-log-files $DB_NAME --access-key-id $ACCESS_KEY --secret-key $SECRET_KEY | awk '{print $2}')

oldIFS="$IFS"
IFS='
'
IFS=${IFS:0:1}
lines=( $files )
IFS="$oldIFS"

for line in "${lines[@]}"
    do
        if [ -e ${line:6} ]
        then echo ${line:6} "already exists"
        else
            echo ${line:6} "doesnt exist, downloading"
            rds-download-db-logfile $DB_NAME --log-file-name $line  --access-key-id $ACCESS_KEY --secret-key $SECRET_KEY --connection-timeout 3000000 > ${line:6} || echo ${line:6} "couldn't be downloaded"
            echo "done with" ${line:6}
        fi
done

exit 0
