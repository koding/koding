#!/bin/bash

HOST_IP=`boot2docker ssh ip addr show eth1 |sed -nEe 's/^[ \t]*inet[ \t]*([0-9.]+)\/.*$/\1/p'`
mongodump -h$HOST_IP:27017 -dkoding -odump
rm ./default-db-dump.tar.bz2
tar jcvf default-db-dump.tar.bz2 dump
rm -rf dump
echo "All done."