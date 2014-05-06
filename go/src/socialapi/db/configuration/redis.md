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
```

Copy the template configuration file you'll find in the root directory of the Redis distribution into /etc/redis/ using the port number as name, for instance:

`sudo cp redis.conf /etc/redis/6379.conf`
