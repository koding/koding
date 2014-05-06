## Configuring Redis

# Master


Create a directory where to store your Redis config files and your data:
```
sudo mkdir -p /etc/redis
sudo mkdir -p /var/redis
```

Copy the template configuration file you'll find in the root directory of the Redis distribution into /etc/redis/ using the port number as name, for instance:

`sudo cp redis.conf /etc/redis/6379.conf`
