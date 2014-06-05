#!/bin/bash

backup_dir=/backup/redis/full
today=$(date +%Y-%m-%d.%H:%M:%S)
hostname=$(hostname)

if [ $? = 0 ]
then
    mkdir -p $backup_dir/$today
    tar cvj -f $backup_dir/$today/all.tar.bz2 /data/redis/main/dump.rdb

    cd $backup_dir
    # keep last 15
    ls -1d * | sort -rn | tail -n +96 | xargs rm -vr
    cd $OLDPWD
    echo "backup completed database on $today - $hostname" | mail -s "[$today] backup completed" cihangir@koding.com

else
    echo "could not backup database on $today - $hostname" | mail -s "[$today] backup failure  " cihangir@koding.com
fi
