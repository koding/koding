#!/usr/bin/python

import db_conf

import syslog
import time 
import argparse
import sys
import MySQLdb as mysql
from pprint import pprint


# search for overquota db (getOverQutaDbs) -> check if revoked (findNotRevokedDbs) -> revokeWriteAccess 

# search for revoked users (findRevokedDbs) -> check db size
#
#                                                   |
#                                                  / \
#                                                 /   \
#                                               huge   no
#                                                |     |
#                                            done   grant write




class DbQuota(object):
    def __init__(self):
        syslog.openlog(sys.argv[0], syslog.LOG_PID, syslog.LOG_LOCAL6)
        db = mysql.connect(db_conf.db_host, db_conf.db_user, db_conf.db_pass)
        self.c = db.cursor()

    def getOverQutaDbs(self):
        sql = """SELECT table_schema 'db_name', sum(data_length+index_length)/1024/1024 'size_mb'
                 FROM information_schema.TABLES GROUP BY table_schema"""
        self.c.execute(sql)
        overQuotaDbs = [ {'db_name':db[0],'db_size':int(db[1])} 
                            for db in self.c.fetchall() if db[1] > db_conf.db_size_limit
                                                        and db[0] not in db_conf.db_whitelist]
        
        return overQuotaDbs

    def findRevokedDbs(self):
         sql = "SELECT User,Db FROM mysql.db WHERE Insert_priv='N'"
         self.c.execute(sql)
         revoked = [ {'db_user':db[0],'db_name':db[1],'db_size':self.calculateDbSize(db[0])}
                        for db in self.c.fetchall() ]
         if len(revoked) == 0:
            return False
         else:
            return revoked

    def grantWriteAccess(self):
        sql = "GRANT INSERT,UPDATE,CREATE ON %s.* TO '%s'@'%%'"
        dbs = self.findRevokedDbs()
        if dbs:
            for db in dbs:
                if db['db_size'] < db_conf.db_size_limit:
                    print(sql % (db['db_name'],db['db_user']))
                    syslog.syslog(syslog.LOG_INFO, sql % (db['db_name'],db['db_user']))
                    self.c.execute(sql % (db['db_name'],db['db_user']))
                    self.killUsersSession(db['db_user'])
                else:
                    print("db %s still huge: %s MB" % (db['db_name'],db['db_size']))
                    syslog.syslog(syslog.LOG_INFO, "db %s still huge: %s MB" % (db['db_name'],db['db_size']))
        else:
            syslog.syslog(syslog.LOG_INFO, "there is no dbs for GRANT")
            print("there is no dbs for GRANT")


    def findNotRevokedDbs(self):
        sql = "SELECT Db,Insert_priv FROM mysql.db WHERE Db='%s'"
        dbs = self.getOverQutaDbs()
        not_revoked = []
        for db in dbs:
            self.c.execute(sql % (db['db_name']))
            db,revoke_status = self.c.fetchone()
            if revoke_status == "Y":
                not_revoked.append(db)
        if len(not_revoked) > 0:
            return not_revoked
        else:
            return False
    
    def calculateDbSize(self,db):
       sql = """SELECT SUM(ROUND(((DATA_LENGTH+INDEX_LENGTH)/1024/1024),2)) 'size'
                FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='%s'"""
       
       self.c.execute(sql % db)
       return int(self.c.fetchone()[0])
       

    def killUsersSession(self,user):
        sql = "select ID FROM information_schema.PROCESSLIST where USER='%s'"
        kill = "CALL mysql.rds_kill(%d)"

        self.c.execute(sql % user)
        for procID in self.c.fetchall():
            num = self.c.execute(kill % int(procID[0]))
            print("killed %d for user %s" % (procID[0],user))
            syslog.syslog(syslog.LOG_INFO, "killed %d for user %s" % (procID[0],user))
        return True

    def revokeWriteAccess(self):
        find_user = "SELECT User FROM mysql.db WHERE Db='%s'"
        revoke_access = "REVOKE INSERT,UPDATE,CREATE ON %s.* FROM '%s'@'%%'";
        dbs = self.findNotRevokedDbs()
        if dbs:
            for db in dbs:
                self.c.execute(find_user % (db))
                user, = self.c.fetchone()
                print("revoking access on db %s for user %s" % (db,user))
                syslog.syslog(syslog.LOG_INFO, "revoking access on db %s for user %s" % (db,user))
                self.c.execute(revoke_access % (db, user))
                self.killUsersSession(user)
        else:
            #print("all write permissions on huge DBs already revoked")
            syslog.syslog(syslog.LOG_INFO, "all write permissions on huge DBs already revoked")


if __name__ == "__main__":
    quota = DbQuota()
    parser = argparse.ArgumentParser(description="MySQL quotas")
    parser.add_argument('--revoke', dest='revoke',help='revoke access',action='store_true')
    parser.add_argument('--grant', dest='grant',help='grant access',action='store_true')
    args = parser.parse_args()

    if args.revoke:    
        quota.revokeWriteAccess()
    if args.grant:
        quota.grantWriteAccess()
