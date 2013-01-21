#!/usr/bin/env python
__author__ = 'Aleksey Mykhailov'
__email__  = 'aleksey@koding.com'

import pymongo
import os
import sys
import syslog
import hashlib


mongo_host  = 'web0.beta.system.aws.koding.com'
mongo_user  = 'PROD-koding'
mongo_pass  = '34W4BXx595ib3J72k5Mh'
database    = 'beta_koding'
collection  = 'jUsers'

syslog.openlog("mongoauth",syslog.LOG_PID,syslog.LOG_AUTH)



try:
    username = os.environ['AUTHD_ACCOUNT']
    password = os.environ['AUTHD_PASSWORD']
except KeyError,e:
    print ("Env variable %s wasn't provided" % e)
    sys.exit(1)


try:
    connection = pymongo.Connection(mongo_host, 27017)
    db = pymongo.database.Database(connection, database)
    db.authenticate(mongo_user,mongo_pass)
    ftp_collection = pymongo.collection.Collection(db,collection)
except pymongo.errors.InvalidName,e:
    syslog.syslog(syslog.LOG_ERR,str(e))
    print("err: %s" % e )
    sys.exit(1)
except pymongo.errors.OperationFailure,e:
    syslog.syslog(syslog.LOG_ERR,str(e))
    print("database operation fails: %s" % e )
    sys.exit(1)
except pymongo.errors.ConnectionFailure,e:
    syslog.syslog(syslog.LOG_ERR,str(e))
    print("connection error: %s" % e )
    sys.exit(1)

user_data = ftp_collection.find_one({"username":username})

#syslog.syslog(syslog.LOG_DEBUG,str(user_data))
if user_data is None:
    #wrong username (no records in the mognodb collection)
    syslog.syslog(syslog.LOG_WARNING,"Can't find user %s in the mongo" % username)
    sys.stdout.write('auth_ok:0\n')
    sys.stdout.write('end\n')
else:
    #if user_data["password"] in hash.hexdigest():
    password = hashlib.sha1( user_data['salt'] + password ).hexdigest()
    if user_data["password"] == password:
        owner = os.lstat('/Users/%s' % username)
        syslog.syslog(syslog.LOG_ERR,"user %s accepted with UID: %s and GID: %s" % (username,owner.st_uid,owner.st_gid))
        sys.stdout.write('auth_ok:1\n')
        sys.stdout.write('uid:%s\n' % owner.st_uid)
        sys.stdout.write('gid:%s\n' % owner.st_gid)
        sys.stdout.write('dir:/Users/%s\n' % username)
        sys.stdout.write('end\n')
        sys.exit(0)
    else:
        syslog.syslog(syslog.LOG_WARNING,"wrong password for username %s , pass: %s" % (username,os.environ['AUTHD_PASSWORD']))
        sys.stdout.write('auth_ok:0\n')
        sys.stdout.write('end\n')
        sys.exit(1)

