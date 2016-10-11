#!/bin/bash
HOST_IP=${HOST_IP:-`boot2docker ip ||`}
HOST_IP=${HOST_IP:-`docker-machine ip`}
mongodump -h$HOST_IP:27017 -dkoding -odump
rm ./default-db-dump.tar.bz2
tar -jcvf default-db-dump.tar.bz2 dump
rm -rf dump
echo "All done."

echo "do not forget to ./run updatepermissions too."
