## Configuring Redis

# Master


Create a directory where to store data:
```
sudo mkdir -p /data/redis/main

chown -R redis:redis /data/redis
```

Set followings

```
daemonize yes
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log
```

 Do not save anything on master redis
```
appendonly no
```

# Slave

Set as slave of `social-redis-a.sj.koding.com 6379`
```
slaveof 172.16.10.16 6379
```

```
slave-serve-stale-data yes

slave-read-only yes

appendonly yes
```


# Server

Not set for now, if we are gonna use more memory than needed, use this
```
vm.overcommit_memory = 1
```


# Set Max open file descriptor
cat /proc/sys/fs/file-max
be sure it has more than 90K
