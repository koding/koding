#!/usr/bin/env python
__author__ = 'Aleksey Mykhailov'
__email__  = 'aleksey@koding.com'


import config
import sys
import datetime

from pymongo import Connection
from pymongo.errors import ConnectionFailure
from pymongo.errors import OperationFailure

current_month = datetime.datetime.now().strftime('%b')


try:
    connection = Connection(config.mongo_host, 27017)
    #print("Connected to %s" % config.mongo_host)
except ConnectionFailure as (strerror):
    sys.stderr.write("Could not connect to mongoDB: %s" % strerror)
    sys.exit(1)

db_handle = connection[config.database]
assert db_handle.connection == connection
db_handle.authenticate(config.mongo_user,config.mongo_pass)


try:
    vhosts = db_handle.pervhost_traff.find({'monthlyStat' :{'$elemMatch':{'month':current_month,'out':{'$gt':config.max_traff_usage}}}})
    for vhost in vhosts:
        month_stat = vhost.get('monthlyStat')
        for month in month_stat:
            if month.get('month') == current_month:
                print ("%s %s %s Mb" % (vhost.get('vhostname'),month.get('month'),month.get('out')/1024))

except OperationFailure as (strerror):
    sys.stderr.write("Could not query mongoDB: %s" % strerror)
    sys.exit(1)

