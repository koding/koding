# Important
## We are only writing/persisting on slave machine
## so, backup operation should be done on slave machine

# RDB + AOF together

With AOF, the process is a little bit more involved. When Redis starts, it looks at the AOF log as the primary source of information because it has always the newest data available. The problem is that if we only have a RDB snapshot and no AOF log (or we have a log but it has been affected by the accident so we cannot use it), Redis would still use the AOF log as the only data source. And since the log is missing (same as empty), it would not load any data at all and create a new empty snapshot file.

The following solution takes advantage of the fact that you can recreate the AOF log from the current dataset even if the AOF mode is currently disabled.

Similar to the RDB only, without AOF section, take down the server, delete any snapshots and logs and finally copy the backup dump.rdb file.
```
$ sudo rm -f dump.rdb appendonly.aof
$ sudo cp /backup/dump.rdb .
$ sudo chown redis:redis dump.rdb

```

Now the interesting part. Go to the configuration file (/etc/redis/redis.conf) and disable AOF:

`appendonly no`
Next, start the Redis server and issue the BGREWRITEAOF command:
```
$ sudo monit start redis-server
$ redis-cli BGREWRITEAOF

```

It might take some time, you can check the progress by looking at the aof_rewrite_in_progress value from the info command (0 - done, 1 - not yet):

`$ redis-cli info | grep aof_rewrite_in_progress`
Once it's done, you should see a brand new appendonly.aof file. Next, stop the server, turn the AOF back on and start the server again.

Now you might be asking why we don't just backup the AOF log. The answer is that you could but the AOF logs tend to get really large and we don't usually want to waste disk space.

## redis_backup.sh is in the same directory



# Edit crontab

# Do BGSAVE, every 15 mins, 5 mins before backup
10,25,40,55 * * * *  redis-cli bgsave

# Every 15 mins
0,15,30,45 * * * * /root/backup.sh >> /var/log/redis-backup.log

