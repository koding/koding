# -- Only Master Changes

## Create Data directory $PGDATA
```
/data/postgresql/data
```

## Note: if you create a tablespace inside of data dir, you will end up in tears
## So, /data/postgresql/<data> is there for that reason
## create your tablespaces next to ../data dir

## Make sure master is listening to the slave
```
$ $EDITOR postgresql.conf

listen_addresses = '192.168.0.10' # sample ip

```

## Make sure you gave the permission for Replication
```
# The standby server must connect with a user that has replication privileges.
host  replication  replication  192.168.0.20/22  trust

```

# Do followings on Primary Database

## Enable Slave as a Hot-Standby server

```
# To enable read-only queries on a standby server, wal_level must be set to
# "hot_standby". But you can choose "archive" if you never connect to the
# server in standby mode.
wal_level = hot_standby

```

## Set the maximum number of concurrent connections from the standby servers.
```
max_wal_senders = 5

```

## Increase WAL segments count
```
# To prevent the primary server from removing the WAL segments required for
# the standby server before shipping them, set the minimum number of segments
# retained in the pg_xlog directory. At least wal_keep_segments should be
# larger than the number of segments generated between the beginning of
# online-backup and the startup of streaming replication. If you enable WAL
# archiving to an archive directory accessible from the standby, this may
# not be necessary.
wal_keep_segments = 32

```

## Restart Primary Server


# Slave Changes

## Clear Data directory

## Get a backup from Master
```

rsync -ac /data/postgresql/ 172.16.3.20:/data/postgresql --exclude postmaster.pid

pg_basebackup -R -D $PGDATA --host=<host>
pg_basebackup --write-recovery-conf --pgdata=/data/postgresql --host 172.16.3.18 --progress --verbose

```
###The -R option (version 9.3+) will create a minimal recovery command file.

## Create a trigger file config for slave to make it master

### Specifies a trigger file whose presence should cause streaming replication to end
```
nano $PGDATA/recovery.conf
trigger_file = '$PGDATA/makememaster'

```
