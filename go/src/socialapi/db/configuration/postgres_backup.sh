#!/bin/bash

backup_dir=/backup/postgresql/full
wal_dir=/backup/postgresql/wal_archive
today=$(date +%Y-%m-%d.%H:%M:%S)
lastOne=$(find $backup_dir -maxdepth 1 -type d -name "*" -exec basename {} \; | tail -n +2 | sort -rn | head -1)

psql -c "select pg_start_backup('$today', true);"
hostname=$(hostname)

if [ $? = 0 ]
then
    mkdir -p $backup_dir/$today
    tar cvj --one-file-system -f $backup_dir/$today/base.tar.bz2 /data/postgresql/data
    psql -c 'select pg_stop_backup();'

    cd $wal_dir
    # find the latest numerical *.backup file and extract the wal segment name it applies to
    breakpoint=`ls *.backup | sort -r | head -n1 | sed -e 's/\..*$//'`

    # get the linenumber of applicable wal segment in the directory listing, generate a list to
    # archive of all those that are in that first set of lines, including the backup wal segment
    arline=`ls | sort | sed -ne "/^$breakpoint$/ =" `
    archive=`ls | sort | head -n $arline`

    # get the line number of the wal segment immediately before the backup. generate the list to
    # remove of all those in that set of lines, excluding the backup wal segment
    rmline=`echo "$arline - 1" | bc`
    remove=`ls | sort | head -n $rmline`
    echo $remove
    tar cvjf $backup_dir/$lastOne/full-wal.tar.bz2 $archive
    rm $remove
    tar cvjf $backup_dir/$today/pit-wal.tar.bz2 $wal_dir

    cd $backup_dir
    # keep last 15
    ls -1d * | sort -rn | tail -n +15 | xargs rm -vr
    cd $OLDPWD
    echo "backup completed database on $today - $hostname" | mail -s "[$today] backup completed" cihangir@koding.com

else
    echo "could not backup database on $today - $hostname" | mail -s "[$today] backup failure  " cihangir@koding.com
fi
