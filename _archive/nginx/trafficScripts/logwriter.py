#!/usr/bin/env python
__author__ = 'Aleksey Mykhailov'
__email__  = 'aleksey@koding.com'


#Usage:
#  0. create mongo capped collection for traffic logs ( "db.createCollection("traffic", {capped:true, size:104857600})" )
#  1. configure nginx log format. add folowing lines to vhost config
#    log_format hostinglog   '{"vhostname":"$http_host",
#                              "out":"$bytes_sent",
#                              "request":"$request",
#                              "date":"$time_local",
#                              "iscounted":"false"}';
#    access_log  /var/log/nginx/hosting.traffic.log hostinglog;
#  2. tail -F /var/log/nginx/hosting.traffic.log | /path/to/this/logwriter.py

import sys
import os
from pymongo import Connection
from pymongo.errors import ConnectionFailure
from pymongo.errors import OperationFailure
import config
import logParser




def main():

    try:
        # special for monit
        pid = os.getpid()
        pid_handle = open(config.logwriter_pid_file,'w')
        pid_handle.write(str(pid))
        pid_handle.close()
    except IOError,e:
        sys.stderr.write("Could not write pid file: %s" % e)
        sys.exit(1)

    try:
        connection = Connection(config.mongo_host, 27017)
        print("Connected to %s" % config.mongo_host)
    except ConnectionFailure,e:
        sys.stderr.write("Could not connect to mongoDB: %s" % e)
        sys.exit(1)

    db_handle = connection[config.database]
    assert db_handle.connection == connection
    db_handle.authenticate(config.mongo_user,config.mongo_pass)

    while 1:
        line = sys.stdin.readline()
        if not line:
            break
        if not config.isLogFormated: line = logParser.parse(line)
        if line:
            if config.debug:
                sys.stdout.write(line)
                try:
                    open(config.logwriter_log_file,'a+').write(line)
                except IOError,e:
                    sys.stderr.write("Could not write log file: %s" % e)
            try:
                db_handle.traffic.insert(eval(line),safe=True)
            except OperationFailure,e:
                sys.stderr.write("Could not insert data to mongoDB collection: %s" % e)
                sys.exit(1)
        else:
            pass




if __name__ == '__main__':
    main()